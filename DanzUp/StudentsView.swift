import SwiftUI

struct StudentsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var showAdd = false

    var filtered: [Student] {
        search.isEmpty ? store.students : store.students.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.course.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            ForEach(filtered) { student in
                NavigationLink {
                    StudentDetailView(student: student)
                } label: {
                    HStack(spacing: 14) {
                        Text(initials(student.name))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(BrandGradient())
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(student.name).font(.headline)
                            Text(student.course).font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 7) {
                                StatusPill(text: student.paymentStatus.rawValue, color: student.paymentStatus.color)
                                StatusPill(text: "Pres. \(student.attendanceRate)%", color: Color.dzPurple)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .swipeActions {
                    Button(role: .destructive) { store.students.removeAll { $0.id == student.id } } label: { Label("Elimina", systemImage: "trash") }
                }
            }
        }
        .navigationTitle("Allievi")
        .searchable(text: $search, prompt: "Cerca allievo o corso")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showAdd = true } label: { Image(systemName: "person.badge.plus") } } }
        .sheet(isPresented: $showAdd) { AddStudentView() }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text).font(.caption2.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }
}

struct StudentDetailView: View {
    let student: Student
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 64)).foregroundStyle(Color.dzPurple)
                    VStack(alignment: .leading) {
                        Text(student.name).font(.title2.bold())
                        Text("\(student.age) anni • \(student.course)").foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
            }
            Section("Situazione") {
                LabeledContent("Pagamento", value: student.paymentStatus.rawValue)
                LabeledContent("Certificato", value: student.medicalStatus.rawValue)
                LabeledContent("Presenze", value: "\(student.attendanceRate)%")
            }
            Section("Azioni rapide") {
                NavigationLink { PaymentsManagementView(initialFilter: student.paymentStatus == .late ? "Scadute" : "Tutte") } label: { Label("Registra pagamento", systemImage: "eurosign.circle") }
                NavigationLink { OwnerAttendanceView() } label: { Label("Segna presenza", systemImage: "checkmark.circle") }
                NavigationLink { CommunicationsManagementView(openComposerOnAppear: true) } label: { Label("Invia comunicazione", systemImage: "paperplane") }
                NavigationLink { MedicalCertificatesView(showOnlyAlerts: false) } label: { Label("Gestisci certificato", systemImage: "cross.case.fill") }
            }
        }
        .navigationTitle("Scheda allievo")
    }
}

struct AddStudentView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var course = ""
    @State private var age = 12

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome e cognome", text: $name)
                TextField("Corso", text: $course)
                Stepper("Età: \(age)", value: $age, in: 3...99)
            }
            .navigationTitle("Nuovo allievo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        store.students.append(Student(name: name.isEmpty ? "Nuovo allievo" : name, course: course.isEmpty ? "Da assegnare" : course, age: age, paymentStatus: .due, medicalStatus: .expiring, attendanceRate: 0))
                        dismiss()
                    }
                }
            }
        }
    }
}
