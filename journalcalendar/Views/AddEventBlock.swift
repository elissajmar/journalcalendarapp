//
//  AddEventBlock.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/13/26.
//

import SwiftUI

struct AddEventBlock: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ModelData.self) var modelData
    @Environment(AuthController.self) var auth
    @Environment(CalendarService.self) var calendarService
   

    
    var initialDate: Date
    
    @State private var title: String = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var subBlocks: [SubBlock] = []
    
    @State private var inviteeEmail: String = ""
    @State private var isCreating: Bool = false
    
    init(initialDate: Date) {
        self.initialDate = initialDate
        
        // Set default times: start at next hour, end 1 hour later
        let calendar = Calendar.current
        let now = initialDate
        let currentHour = calendar.component(.hour, from: now)
        let nextHour = (currentHour + 1) % 24
        
        let startDate = calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: now) ?? now
        let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        
        _startTime = State(initialValue: startDate)
        _endTime = State(initialValue: endDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    // Title and time
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Add title", text: $title)
                            .font(.heading3)
                            .foregroundStyle(title.isEmpty ? .secondary : .primary)
                            .textFieldStyle(.plain)
                        
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            
                            Text("to")
                                .labelStyle()
                            
                            DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Invite a Friend")
//                            .font(.label)
//                            .foregroundStyle(.secondary)
//                        
//                        TextField("Email Address", text: $inviteeEmail)
//                            .textFieldStyle(.roundedBorder)
//                            .autocorrectionDisabled()
//                            .textInputAutocapitalization(.never)
//                            .keyboardType(.emailAddress)
//                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invite a Friend")
                            .font(.label)
                            .foregroundStyle(.secondary)
                        
                        TextField("Email Address", text: $inviteeEmail)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    
                    SubBlockEditor(subBlocks: $subBlocks)
                }
                .padding()
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            createBlock()
                        } label: {
                            HStack(spacing: 8) {
                                if isCreating {
                                    ProgressView()
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text("Create")
                            }
                            .font(.label)
                            .textCase(.uppercase)
                        }
                        .buttonStyle(.plain)
                        .disabled(title.isEmpty || isCreating)
                        .opacity(title.isEmpty || isCreating ? 0.5 : 1.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    private func createBlock() {
        guard let userId = auth.currentUserId else { return }
        isCreating = true
        
        Task {
            // 1. Create the event and get the ID back
            let newBlockId = await modelData.createBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                subBlocks: subBlocks,
                userId: userId
            )
            
            // 2. If the block was created and an email was provided, send the invite
            if let eventId = newBlockId, !inviteeEmail.isEmpty {
                await modelData.inviteUser(email: inviteeEmail, to: eventId)
            }
            
            isCreating = false
            dismiss()
        }
    }
}



#Preview {
    // 1. Setup the state for the sheet
    @Previewable @State var showSheet = true
    
    // 2. Initialize all the dependencies the view expects
    let modelData = ModelData.preview()
    let authController = AuthController() // Crucial: AddEventBlock needs 'auth'
    let calendarService = CalendarService() // Crucial: Needed for invitee logic
    
    return Color.clear
        .sheet(isPresented: $showSheet) {
            AddEventBlock(initialDate: Date())
                .environment(modelData)
                .environment(authController)
                .environment(calendarService)
        }
        .onAppear {
            showSheet = true
        }
}
