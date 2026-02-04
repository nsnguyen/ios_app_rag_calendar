import SwiftUI
import SwiftData
import CoreSpotlight

struct DataSettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices
    @State private var meetingCount = 0
    @State private var noteCount = 0
    @State private var embeddingCount = 0
    @State private var meetingEmbeddingCount = 0
    @State private var noteEmbeddingCount = 0
    @State private var personCount = 0
    @State private var taskCount = 0
    @State private var showDeleteConfirmation = false
    @State private var isRebuilding = false
    @State private var isLoadingSampleData = false
    @State private var meetingSummaries: [(title: String, date: String)] = []

    var body: some View {
        List {
            Section("Storage") {
                dataRow("Meetings", count: meetingCount, icon: "calendar")
                dataRow("Notes", count: noteCount, icon: "note.text")
                dataRow("Tasks", count: taskCount, icon: "checkmark.circle")
                dataRow("People", count: personCount, icon: "person.2")
                dataRow("Embeddings (Total)", count: embeddingCount, icon: "brain")
                dataRow("  - Meeting chunks", count: meetingEmbeddingCount, icon: "calendar.badge.clock")
                dataRow("  - Note chunks", count: noteEmbeddingCount, icon: "note.text.badge.plus")
            }

            if !meetingSummaries.isEmpty {
                Section("Synced Meetings") {
                    ForEach(meetingSummaries, id: \.date) { item in
                        HStack {
                            Text(item.title)
                                .font(theme.typography.bodyFont)
                            Spacer()
                            Text(item.date)
                                .font(theme.typography.captionFont)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    loadSampleData()
                } label: {
                    HStack {
                        Text("Load Sample Data")
                        if isLoadingSampleData {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isLoadingSampleData)

                Button("Rebuild Search Index", role: .none) {
                    rebuildIndex()
                }
                .disabled(isRebuilding)

                Button("Delete All Data", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } header: {
                Text("Actions")
            } footer: {
                Text("Load sample data to test RAG search. All data is stored locally on your device.")
            }
        }
        .navigationTitle("Data & Storage")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all meetings, notes, people, and search data.")
        }
        .task {
            await refreshCounts()
        }
    }

    private func dataRow(_ label: String, count: Int, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text("\(count)")
                .foregroundStyle(theme.colors.textSecondary)
        }
    }

    private func refreshCounts() async {
        meetingCount = (try? modelContext.fetchCount(FetchDescriptor<MeetingRecord>())) ?? 0
        noteCount = (try? modelContext.fetchCount(FetchDescriptor<Note>())) ?? 0
        embeddingCount = (try? modelContext.fetchCount(FetchDescriptor<EmbeddingRecord>())) ?? 0
        personCount = (try? modelContext.fetchCount(FetchDescriptor<Person>())) ?? 0
        taskCount = (try? modelContext.fetchCount(FetchDescriptor<DayTask>())) ?? 0

        // Count embeddings by type
        let allEmbeddings = (try? modelContext.fetch(FetchDescriptor<EmbeddingRecord>())) ?? []
        meetingEmbeddingCount = allEmbeddings.filter { $0.sourceType == "meeting" }.count
        noteEmbeddingCount = allEmbeddings.filter { $0.sourceType == "note" }.count

        let descriptor = FetchDescriptor<MeetingRecord>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        let meetings = (try? modelContext.fetch(descriptor)) ?? []
        meetingSummaries = meetings.map { meeting in
            (
                title: meeting.title,
                date: meeting.startDate.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    private func rebuildIndex() {
        isRebuilding = true
        let ragService = appServices.ragService
        let spotlightService = appServices.spotlightService

        Task.detached(priority: .utility) {
            let context = ModelContext(SharedModelContainer.shared)
            let meetings = (try? context.fetch(FetchDescriptor<MeetingRecord>())) ?? []
            for meeting in meetings {
                ragService.indexMeetingRecord(meeting, context: context)
                spotlightService.indexMeeting(meeting)
            }
            let notes = (try? context.fetch(FetchDescriptor<Note>())) ?? []
            for note in notes {
                ragService.indexNote(note, context: context)
                spotlightService.indexNote(note)
            }
            await MainActor.run { isRebuilding = false }
        }
    }

    private func deleteAllData() {
        // Delete in dependency order: embeddings first, then notes, then meetings, then people/tags
        // Fetch and delete individually to handle relationships properly

        // 1. Delete all embeddings
        let embeddingDescriptor = FetchDescriptor<EmbeddingRecord>()
        if let embeddings = try? modelContext.fetch(embeddingDescriptor) {
            for embedding in embeddings {
                modelContext.delete(embedding)
            }
        }

        // 2. Delete all notes
        let noteDescriptor = FetchDescriptor<Note>()
        if let notes = try? modelContext.fetch(noteDescriptor) {
            for note in notes {
                modelContext.delete(note)
            }
        }

        // 3. Delete all meetings
        let meetingDescriptor = FetchDescriptor<MeetingRecord>()
        if let meetings = try? modelContext.fetch(meetingDescriptor) {
            for meeting in meetings {
                modelContext.delete(meeting)
            }
        }

        // 4. Delete all people
        let personDescriptor = FetchDescriptor<Person>()
        if let people = try? modelContext.fetch(personDescriptor) {
            for person in people {
                modelContext.delete(person)
            }
        }

        // 5. Delete all tags
        let tagDescriptor = FetchDescriptor<Tag>()
        if let tags = try? modelContext.fetch(tagDescriptor) {
            for tag in tags {
                modelContext.delete(tag)
            }
        }

        // 6. Delete all tasks
        let taskDescriptor = FetchDescriptor<DayTask>()
        if let tasks = try? modelContext.fetch(taskDescriptor) {
            for task in tasks {
                modelContext.delete(task)
            }
        }

        // Save changes
        try? modelContext.save()

        // Clear Spotlight index
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }

        Task { await refreshCounts() }
    }

    private func loadSampleData() {
        isLoadingSampleData = true
        let ragService = appServices.ragService
        let spotlightService = appServices.spotlightService

        Task.detached(priority: .userInitiated) {
            let context = ModelContext(SharedModelContainer.shared)
            let sampleData = SampleDataGenerator.generate()

            // Insert people first
            for person in sampleData.people {
                context.insert(person)
            }

            // Insert meetings with attendees
            for (meeting, attendeeEmails) in sampleData.meetings {
                context.insert(meeting)
                for email in attendeeEmails {
                    if let person = sampleData.people.first(where: { $0.email == email }) {
                        meeting.attendees.append(person)
                        person.meetingCount += 1
                        person.lastSeenDate = meeting.startDate
                    }
                }
                ragService.indexMeetingRecord(meeting, context: context)
                spotlightService.indexMeeting(meeting)
            }

            // Insert notes
            for note in sampleData.notes {
                context.insert(note)
            }

            // Insert tasks
            for task in sampleData.tasks {
                context.insert(task)
            }

            // Save all data before indexing
            try? context.save()

            // Now index notes (after they're persisted)
            for note in sampleData.notes {
                ragService.indexNote(note, context: context)
                spotlightService.indexNote(note)
            }

            // Final save for embeddings
            try? context.save()
            await MainActor.run {
                isLoadingSampleData = false
                Task { await refreshCounts() }
            }
        }
    }
}

// MARK: - Sample Data Generator

private enum SampleDataGenerator {
    struct SampleData {
        let people: [Person]
        let meetings: [(MeetingRecord, [String])] // meeting + attendee emails
        let notes: [Note]
        let tasks: [DayTask]
    }

    static func generate() -> SampleData {
        let calendar = Calendar.current
        let today = Date()

        // Create people I frequently meet with
        let sarah = Person(email: "sarah.chen@company.com", name: "Sarah Chen")
        let mike = Person(email: "mike.rodriguez@company.com", name: "Mike Rodriguez")
        let emma = Person(email: "emma.wilson@design.co", name: "Emma Wilson")
        let david = Person(email: "david.kim@startup.io", name: "David Kim")
        let lisa = Person(email: "lisa.zhang@investor.vc", name: "Lisa Zhang")
        let james = Person(email: "james.patel@company.com", name: "James Patel")
        let rachel = Person(email: "rachel.green@marketing.com", name: "Rachel Green")
        let tom = Person(email: "tom.hanks@legal.firm", name: "Tom Hanks")
        let amy = Person(email: "amy.liu@company.com", name: "Amy Liu")
        let chris = Person(email: "chris.martin@engineering.co", name: "Chris Martin")

        let people = [sarah, mike, emma, david, lisa, james, rachel, tom, amy, chris]

        var meetings: [(MeetingRecord, [String])] = []

        // Past meetings with rich context

        // 3 weeks ago - Product strategy with Sarah
        let meeting1 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Q1 Product Roadmap Review",
            startDate: calendar.date(byAdding: .day, value: -21, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -21, to: today)!.addingTimeInterval(3600),
            location: "Conference Room A",
            meetingNotes: """
            Sarah presented the Q1 roadmap priorities. We discussed the mobile app redesign timeline \
            and agreed to push the launch to mid-February to ensure quality. Key features include \
            the new dashboard widgets and improved notification system. Budget approved for two \
            additional contractors. Sarah mentioned concerns about the API migration timeline \
            conflicting with the iOS release.
            """,
            purpose: "Review and finalize Q1 product priorities",
            outcomes: "Approved roadmap with February launch target",
            actionItems: "1. Sarah to update timeline docs\n2. I need to review contractor proposals\n3. Schedule follow-up with engineering"
        )
        meetings.append((meeting1, ["sarah.chen@company.com"]))

        // 2.5 weeks ago - Design review with Emma
        let meeting2 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Mobile App Design Review",
            startDate: calendar.date(byAdding: .day, value: -18, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -18, to: today)!.addingTimeInterval(5400),
            location: "Zoom",
            meetingNotes: """
            Emma walked through the new mobile app designs. The onboarding flow looks much cleaner now. \
            We debated the color palette - I prefer the warmer tones but Emma made good points about \
            accessibility with the cooler blues. Decided to A/B test both versions. Emma will send \
            the Figma links by Friday. She mentioned wanting to explore micro-animations for the \
            dashboard transitions. Cost estimate for the full redesign is $45,000.
            """,
            purpose: "Review mobile app redesign concepts",
            outcomes: "Approved designs with A/B test plan for color schemes",
            actionItems: "1. Emma sends Figma links\n2. Set up A/B test infrastructure\n3. Review animation proposals"
        )
        meetings.append((meeting2, ["emma.wilson@design.co"]))

        // 2 weeks ago - Investor meeting with Lisa
        let meeting3 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Series B Discussion with Horizon Ventures",
            startDate: calendar.date(byAdding: .day, value: -14, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -14, to: today)!.addingTimeInterval(3600),
            location: "Lisa's office - 500 Tech Blvd",
            meetingNotes: """
            Met with Lisa Zhang from Horizon Ventures about potential Series B. She's interested \
            but wants to see stronger unit economics before committing. Discussed our CAC payback \
            period (currently 18 months, need to get to 12). She suggested focusing on enterprise \
            customers for better margins. Lisa mentioned they typically invest $5-10M in Series B \
            and would want a board seat. She asked about our AI roadmap - I pitched the meeting \
            intelligence features. Follow-up meeting scheduled for next month after we share \
            updated financials.
            """,
            purpose: "Explore Series B funding opportunity",
            outcomes: "Positive initial meeting, need to improve unit economics",
            actionItems: "1. Update financial projections\n2. Prepare enterprise strategy deck\n3. Send AI roadmap one-pager"
        )
        meetings.append((meeting3, ["lisa.zhang@investor.vc"]))

        // 12 days ago - Engineering sync with Chris
        let meeting4 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Backend Architecture Review",
            startDate: calendar.date(byAdding: .day, value: -12, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -12, to: today)!.addingTimeInterval(7200),
            location: "Engineering War Room",
            meetingNotes: """
            Deep dive with Chris on the backend architecture for the new RAG features. Current \
            Postgres setup won't scale for vector search - he recommends adding Pinecone or \
            pgvector extension. Estimated 3 weeks of engineering work. Chris flagged concerns \
            about latency if we use external vector DB. We agreed to prototype both approaches. \
            Also discussed the authentication refactor - moving from JWT to session-based auth \
            for better security. Chris needs two more engineers for Q1 deliverables.
            """,
            purpose: "Technical architecture planning for AI features",
            outcomes: "Decided to prototype vector DB approaches",
            actionItems: "1. Chris creates architecture proposals\n2. Budget review for Pinecone\n3. Interview candidates for engineering roles"
        )
        meetings.append((meeting4, ["chris.martin@engineering.co"]))

        // 10 days ago - Team standup
        let meeting5 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Weekly Product Team Standup",
            startDate: calendar.date(byAdding: .day, value: -10, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -10, to: today)!.addingTimeInterval(1800),
            location: "Slack Huddle",
            meetingNotes: """
            Quick sync with Sarah, Mike, and Amy. Mike is blocked on the payment integration - \
            waiting for Stripe to approve our updated webhook configuration. Amy finished the \
            user research interviews - key insight: users want better calendar integration, \
            specifically with Google Calendar and Outlook. Sarah is on track with the roadmap \
            updates. Team morale seems good after the holiday break.
            """,
            purpose: "Weekly team sync",
            outcomes: "Team aligned on weekly priorities",
            actionItems: "1. Mike to escalate Stripe issue\n2. Amy to share research summary\n3. Prioritize calendar integrations"
        )
        meetings.append((meeting5, ["sarah.chen@company.com", "mike.rodriguez@company.com", "amy.liu@company.com"]))

        // 8 days ago - Legal review with Tom
        let meeting6 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Contract Review - Enterprise Deal",
            startDate: calendar.date(byAdding: .day, value: -8, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -8, to: today)!.addingTimeInterval(3600),
            location: "Tom's office",
            meetingNotes: """
            Reviewed the Acme Corp enterprise contract with Tom. He flagged several liability \
            clauses that need revision - specifically around data breaches and SLA penalties. \
            Recommended we cap liability at 12 months of fees (currently unlimited). Also \
            discussed the non-compete clause which is too broad. Tom will redline the contract \
            and send back by Wednesday. Total deal value is $250K annually - our biggest \
            enterprise customer yet.
            """,
            purpose: "Legal review of enterprise contract",
            outcomes: "Identified contract issues to address",
            actionItems: "1. Tom sends redlined contract\n2. Negotiate liability cap with Acme\n3. Update standard enterprise template"
        )
        meetings.append((meeting6, ["tom.hanks@legal.firm"]))

        // 6 days ago - Marketing sync with Rachel
        let meeting7 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Q1 Marketing Campaign Planning",
            startDate: calendar.date(byAdding: .day, value: -6, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -6, to: today)!.addingTimeInterval(5400),
            location: "Marketing Floor",
            meetingNotes: """
            Rachel presented the Q1 marketing plan. Big push on content marketing - she wants \
            to publish 2 blog posts per week focusing on productivity and AI topics. Proposed \
            budget of $50K for paid acquisition, mostly LinkedIn and Google Ads. We discussed \
            the product launch campaign for the mobile redesign - she suggested a \"New Year, \
            New Productivity\" angle. Also talked about influencer partnerships - Rachel has \
            connections with three productivity YouTubers. I approved the blog content calendar \
            but want to review paid spend after seeing January results.
            """,
            purpose: "Plan Q1 marketing strategy",
            outcomes: "Approved content plan, pending review of paid strategy",
            actionItems: "1. Rachel sends influencer proposals\n2. Review January ad performance\n3. Brief design team on campaign visuals"
        )
        meetings.append((meeting7, ["rachel.green@marketing.com"]))

        // 4 days ago - Startup advisor meeting with David
        let meeting8 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Advisory Session with David",
            startDate: calendar.date(byAdding: .day, value: -4, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -4, to: today)!.addingTimeInterval(3600),
            location: "Coffee at Blue Bottle",
            meetingNotes: """
            Monthly catch-up with David. He shared insights from his experience scaling his \
            startup to 100 employees. Key advice: hire a VP of Engineering before Series B, \
            don't wait. Also suggested we think about international expansion - he had success \
            starting with UK market due to language and similar business culture. David offered \
            to intro me to his VP Eng who might be looking for a new role. We also chatted \
            about work-life balance - he emphasized importance of taking real vacations. \
            Planning trip to Japan in March based on his recommendation.
            """,
            purpose: "Monthly advisory check-in",
            outcomes: "Good strategic advice on hiring and expansion",
            actionItems: "1. David sends VP Eng intro\n2. Research UK market opportunity\n3. Block off vacation time in March"
        )
        meetings.append((meeting8, ["david.kim@startup.io"]))

        // 2 days ago - 1:1 with James
        let meeting9 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "1:1 with James",
            startDate: calendar.date(byAdding: .day, value: -2, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -2, to: today)!.addingTimeInterval(2700),
            location: "My office",
            meetingNotes: """
            Regular 1:1 with James. He's been doing great work on the analytics dashboard. \
            Discussed his career goals - he wants to move into a tech lead role within the \
            next year. I suggested he start mentoring the junior developers and take on more \
            architecture decisions. He mentioned some tension with Mike over code review \
            standards - I'll address this separately. James also asked about the equity \
            refresh program - I promised to follow up with HR. Overall very positive \
            conversation, he seems engaged and motivated.
            """,
            purpose: "Regular 1:1 check-in",
            outcomes: "Aligned on career development path",
            actionItems: "1. Follow up with HR on equity refresh\n2. Talk to Mike about code review process\n3. Set up mentorship pairing for James"
        )
        meetings.append((meeting9, ["james.patel@company.com"]))

        // Yesterday - Product demo
        let meeting10 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Product Demo for Potential Customer",
            startDate: calendar.date(byAdding: .day, value: -1, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -1, to: today)!.addingTimeInterval(3600),
            location: "Zoom",
            meetingNotes: """
            Demo call with a potential enterprise customer - medium-sized consulting firm, \
            about 200 employees. They're currently using Notion but frustrated with performance. \
            Very interested in our AI features, especially meeting summaries and action item \
            extraction. Asked about SSO integration (we have it) and SOC2 compliance (in progress). \
            They want to do a pilot with their strategy team first - about 30 users. I quoted \
            $30/user/month for annual commitment. They'll discuss internally and get back to us \
            next week. Good vibes overall - I'd estimate 60% chance of closing.
            """,
            purpose: "Sales demo for enterprise prospect",
            outcomes: "Positive reception, pilot program proposed",
            actionItems: "1. Send pricing proposal\n2. Share SOC2 timeline\n3. Schedule technical deep-dive if needed"
        )
        meetings.append((meeting10, []))

        // Future meetings

        // Tomorrow - Team planning
        let meeting11 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Sprint Planning",
            startDate: calendar.date(byAdding: .day, value: 1, to: today)!.settingHour(10),
            endDate: calendar.date(byAdding: .day, value: 1, to: today)!.settingHour(11),
            location: "Conference Room B",
            purpose: "Plan upcoming sprint priorities"
        )
        meetings.append((meeting11, ["sarah.chen@company.com", "mike.rodriguez@company.com", "james.patel@company.com", "amy.liu@company.com"]))

        // Day after tomorrow - Follow up with Emma
        let meeting12 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Design Review Follow-up",
            startDate: calendar.date(byAdding: .day, value: 2, to: today)!.settingHour(14),
            endDate: calendar.date(byAdding: .day, value: 2, to: today)!.settingHour(15),
            location: "Zoom",
            purpose: "Review A/B test results and finalize color palette"
        )
        meetings.append((meeting12, ["emma.wilson@design.co"]))

        // 3 days out - Board prep with Sarah
        let meeting13 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Board Meeting Prep",
            startDate: calendar.date(byAdding: .day, value: 3, to: today)!.settingHour(9),
            endDate: calendar.date(byAdding: .day, value: 3, to: today)!.settingHour(10, minute: 30),
            location: "My office",
            purpose: "Prepare deck and talking points for board meeting"
        )
        meetings.append((meeting13, ["sarah.chen@company.com"]))

        // 5 days out - Investor follow-up
        let meeting14 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Series B Follow-up with Lisa",
            startDate: calendar.date(byAdding: .day, value: 5, to: today)!.settingHour(11),
            endDate: calendar.date(byAdding: .day, value: 5, to: today)!.settingHour(12),
            location: "Horizon Ventures Office",
            purpose: "Present updated financials and enterprise strategy"
        )
        meetings.append((meeting14, ["lisa.zhang@investor.vc"]))

        // 7 days out - All hands
        let meeting15 = MeetingRecord(
            eventIdentifier: UUID().uuidString,
            title: "Monthly All-Hands Meeting",
            startDate: calendar.date(byAdding: .day, value: 7, to: today)!.settingHour(16),
            endDate: calendar.date(byAdding: .day, value: 7, to: today)!.settingHour(17),
            location: "Main Conference Room + Zoom",
            purpose: "Company-wide updates and Q&A"
        )
        meetings.append((meeting15, []))

        // Create standalone notes

        let note1 = Note(
            title: "Product Ideas Brainstorm",
            plainText: """
            Ideas for improving user engagement:

            1. Smart meeting prep - automatically pull relevant notes from past meetings with the \
            same attendees. Could use the RAG system to find contextually relevant information.

            2. Weekly digest email - summary of all meetings, action items, and key decisions. \
            Users have asked for this multiple times.

            3. Integration with Slack - post meeting summaries to relevant channels automatically.

            4. Voice notes - let users record quick voice memos that get transcribed and added \
            to meeting records.

            5. Calendar blocking - suggest focus time blocks based on meeting patterns.

            Priority should be #1 since we already have the RAG infrastructure.
            """
        )

        let note2 = Note(
            title: "Competitor Analysis - January",
            plainText: """
            Reviewed main competitors this week:

            Notion: Still the market leader but hearing complaints about performance with large \
            workspaces. Their AI features (Notion AI) are good but generic - not meeting-focused.

            Otter.ai: Strong in transcription but weak in the note-taking and project management \
            side. Could be a partnership opportunity rather than direct competitor.

            Fireflies.ai: Direct competitor for meeting intelligence. Their transcription is better \
            than ours currently, but they don't have the rich note-taking features. Pricing is \
            similar ($18/month vs our $20/month).

            Mem: Interesting approach with AI-first design. Very focused on personal knowledge \
            management. Not a direct threat but worth watching.

            Key differentiator for us: unified system that combines calendar, notes, and AI-powered \
            context. No one else is doing the meeting-context preparation feature we're building.
            """
        )

        let note3 = Note(
            title: "Personal OKRs Q1",
            plainText: """
            Objectives and Key Results for Q1:

            Objective 1: Close Series B funding
            - KR1: Meet with at least 10 potential investors
            - KR2: Improve unit economics to 14-month CAC payback
            - KR3: Secure term sheet by end of March

            Objective 2: Launch mobile app redesign
            - KR1: Ship new onboarding flow by Feb 15
            - KR2: Achieve 4.5+ App Store rating (currently 4.2)
            - KR3: Increase mobile DAU by 40%

            Objective 3: Build high-performing team
            - KR1: Hire VP of Engineering
            - KR2: Reduce voluntary turnover to <10%
            - KR3: Achieve eNPS score of 50+

            Personal goal: Take at least 2 weeks of real vacation this quarter.
            """
        )

        let note4 = Note(
            title: "Japan Trip Planning",
            plainText: """
            Planning trip to Japan for March (David's recommendation):

            Dates: March 15-29 (2 weeks)

            Places to visit:
            - Tokyo (5 days) - Shibuya, Shinjuku, Akihabara, day trip to Hakone
            - Kyoto (4 days) - temples, bamboo forest, geisha district
            - Osaka (3 days) - food scene, day trip to Nara

            Things to book:
            - JR Pass (need to buy before leaving)
            - Ryokan in Hakone (hot springs!)
            - Restaurant reservations in Osaka

            Budget: ~$5000 total including flights

            Need to make sure Sarah and James can cover critical decisions while I'm out. Will \
            set up daily async updates via Loom if needed.
            """
        )

        let note5 = Note(
            title: "Hiring Criteria - VP Engineering",
            plainText: """
            What we need in a VP of Engineering:

            Must haves:
            - 10+ years engineering experience, 5+ in leadership
            - Scaled engineering team from 10 to 50+ engineers
            - Experience with AI/ML products (for our roadmap)
            - Strong technical background but can also manage people
            - Startup experience (Series A or B stage)

            Nice to haves:
            - Mobile development experience (iOS preferred)
            - Previous experience with productivity/SaaS tools
            - Network for recruiting senior engineers

            Red flags:
            - Only big company experience (won't adapt to startup pace)
            - Purely management track without recent technical work
            - Job hopping every 1-2 years

            Compensation range: $250-300K base + 1-1.5% equity

            David's contact (potential candidate): reaching out next week
            """
        )

        let note6 = Note(
            title: "Meeting with Lisa - Prep Notes",
            plainText: """
            Prep for the follow-up meeting with Lisa (Horizon Ventures):

            What she wanted to see:
            1. Path to 12-month CAC payback (currently 18)
            2. Enterprise customer strategy
            3. AI feature roadmap

            Our answers:
            1. CAC improvement plan:
               - Shifting spend from paid to content marketing (lower CAC)
               - Introducing annual plans with 20% discount (better LTV)
               - Enterprise customers have 8-month payback already

            2. Enterprise strategy:
               - Targeting 50-500 employee companies
               - Adding SSO, admin controls, SOC2 compliance
               - Acme Corp deal proves product-market fit

            3. AI roadmap:
               - Meeting prep intelligence (using RAG)
               - Automatic action item extraction
               - Relationship insights across meetings

            Key ask: $7M at $35M pre-money valuation

            Backup position: $5M at $30M if needed
            """
        )

        let notes = [note1, note2, note3, note4, note5, note6]

        // Create sample tasks for various days
        var tasks: [DayTask] = []

        // Today's tasks
        let todayTask1 = DayTask(title: "Review Q1 roadmap document", date: today, sortOrder: 0)
        let todayTask2 = DayTask(title: "Send follow-up email to Lisa", date: today, sortOrder: 1)
        let todayTask3 = DayTask(title: "Prepare demo for enterprise client", date: today, sortOrder: 2)
        todayTask3.isCompleted = true
        tasks.append(contentsOf: [todayTask1, todayTask2, todayTask3])

        // Tomorrow's tasks
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let tomorrowTask1 = DayTask(title: "Sprint planning prep", date: tomorrow, sortOrder: 0)
        let tomorrowTask2 = DayTask(title: "Review contractor proposals", date: tomorrow, sortOrder: 1)
        let tomorrowTask3 = DayTask(title: "Call recruiter about VP Eng role", date: tomorrow, sortOrder: 2)
        tasks.append(contentsOf: [tomorrowTask1, tomorrowTask2, tomorrowTask3])

        // Day after tomorrow
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: today)!
        let dayAfterTask1 = DayTask(title: "Finalize color palette with Emma", date: dayAfter, sortOrder: 0)
        let dayAfterTask2 = DayTask(title: "Update financial projections", date: dayAfter, sortOrder: 1)
        tasks.append(contentsOf: [dayAfterTask1, dayAfterTask2])

        // 3 days out
        let day3 = calendar.date(byAdding: .day, value: 3, to: today)!
        let day3Task1 = DayTask(title: "Draft board meeting slides", date: day3, sortOrder: 0)
        let day3Task2 = DayTask(title: "Review Sarah's timeline docs", date: day3, sortOrder: 1)
        tasks.append(contentsOf: [day3Task1, day3Task2])

        // 5 days out
        let day5 = calendar.date(byAdding: .day, value: 5, to: today)!
        let day5Task1 = DayTask(title: "Print materials for Lisa meeting", date: day5, sortOrder: 0)
        let day5Task2 = DayTask(title: "Rehearse investor pitch", date: day5, sortOrder: 1)
        tasks.append(contentsOf: [day5Task1, day5Task2])

        // Yesterday (some completed)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let yesterdayTask1 = DayTask(title: "Send pricing proposal", date: yesterday, sortOrder: 0)
        yesterdayTask1.isCompleted = true
        let yesterdayTask2 = DayTask(title: "Book flight for March trip", date: yesterday, sortOrder: 1)
        tasks.append(contentsOf: [yesterdayTask1, yesterdayTask2])

        return SampleData(people: people, meetings: meetings, notes: notes, tasks: tasks)
    }
}

// MARK: - Date Helper Extension

private extension Date {
    func settingHour(_ hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self) ?? self
    }
}
