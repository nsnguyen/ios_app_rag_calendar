import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.theme) private var theme
    @Query(sort: \Person.meetingCount, order: .reverse) private var people: [Person]
    @State private var searchText = ""

    var body: some View {
        Group {
            if filteredPeople.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    title: "No People",
                    systemImage: "person.2",
                    description: "People from your calendar events will appear here."
                )
            } else if filteredPeople.isEmpty {
                EmptyStateView(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    description: "No people match \"\(searchText)\"."
                )
            } else {
                List {
                    ForEach(filteredPeople) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            PersonRowView(person: person)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("People")
        .searchable(text: $searchText, prompt: "Search people")
    }

    private var filteredPeople: [Person] {
        if searchText.isEmpty { return people }
        return people.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Person Row

private struct PersonRowView: View {
    @Environment(\.theme) private var theme
    let person: Person

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            PersonAvatarView(name: person.name, size: 44)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(person.name)
                    .font(theme.typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(person.email)
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                Text("\(person.meetingCount)")
                    .font(theme.typography.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.accent)

                Text("meetings")
                    .font(.caption2)
                    .foregroundStyle(theme.colors.textTertiary)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}
