//
//  InviteSubBlockEdit.swift
//  journalcalendar
//

import SwiftUI

struct InviteSubBlockEdit: View {
    @Environment(ModelData.self) var modelData
    @Binding var selectedInvitee: UserSearchResult?
    @Binding var isExpanded: Bool
    var onRemove: () -> Void

    @State private var searchText = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))

                    Text("INVITE")
                        .labelStyle()

                    Spacer()

                    Button {
                        withAnimation {
                            onRemove()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                if let invitee = selectedInvitee {
                    HStack {
                        Text(invitee.email)
                            .font(.paragraph1)
                        Spacer()
                        Button {
                            selectedInvitee = nil
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color("SecondaryButtonFill"))
                    .cornerRadius(8)
                } else {
                    TextField("Search by email", text: $searchText)
                        .font(.paragraph1)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(Color("SecondaryButtonFill"))
                        .cornerRadius(8)
                        .onChange(of: searchText) { _, newValue in
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                guard !Task.isCancelled else { return }
                                searchResults = await modelData.searchUsers(query: newValue)
                            }
                        }

                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults) { user in
                                Button {
                                    selectedInvitee = user
                                    searchText = user.email
                                    searchResults = []
                                } label: {
                                    Text(user.email)
                                        .font(.paragraph1)
                                        .foregroundStyle(Color("TextPrimary"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                }
                                .buttonStyle(.plain)

                                if user.id != searchResults.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color("SecondaryButtonFill"))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}
