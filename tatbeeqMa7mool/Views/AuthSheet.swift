//
//  AuthSheet.swift
//  tatbeeqMa7mool
//

import SwiftUI

struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isIdentified {
                    identifiedContent
                } else {
                    anonymousContent
                }
            }
            .navigationTitle("Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var identifiedContent: some View {
        Section {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Authenticated")
                    .font(.headline)
            }
            LabeledContent("User ID", value: viewModel.currentUserId ?? "—")
        }

        Section {
            Button("Log Out", role: .destructive) {
                viewModel.logout()
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var anonymousContent: some View {
        Section {
            TextField("User ID", text: $viewModel.userIdInput)
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            SecureField("Chatbot Secret", text: $viewModel.secretInput)
        } header: {
            Text("Identity Verification")
        } footer: {
            Text("Signs an HS256 JWT with the given secret and user ID, then authenticates the session.")
        }

        if let error = viewModel.errorMessage {
            Section {
                Text(error).foregroundStyle(.red)
            }
        }

        Section {
            Button {
                Task {
                    await viewModel.identify()
                    if viewModel.isIdentified { dismiss() }
                }
            } label: {
                HStack {
                    if viewModel.isWorking {
                        ProgressView()
                    }
                    Text(viewModel.isWorking ? "Authenticating…" : "Authenticate")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!canSubmit)
        }
    }

    private var canSubmit: Bool {
        !viewModel.userIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.secretInput.isEmpty
            && !viewModel.isWorking
    }
}
