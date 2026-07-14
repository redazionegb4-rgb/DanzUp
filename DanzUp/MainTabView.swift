import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            switch store.userRole {
            case .owner:
                SchoolTabView()
            case .secretary, .teacher:
                StaffTabView()
            case .parent, .student:
                FamilyTabView()
            }
        }
        .tint(.dzPurple)
    }
}

private struct SchoolTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Home", systemImage: "sparkles") }
            NavigationStack { CoursesView() }.tabItem { Label("Corsi", systemImage: "figure.dance") }
            NavigationStack { StudentsView() }.tabItem { Label("Allievi", systemImage: "person.3.fill") }
            NavigationStack { ManagementView() }.tabItem { Label("Gestione", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Scuola", systemImage: "building.2.fill") }
        }
    }
}

private struct StaffTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Oggi", systemImage: "calendar") }
            NavigationStack { StaffCoursesView() }.tabItem { Label("Lezioni", systemImage: "figure.dance") }
            NavigationStack { AttendanceRegisterView() }.tabItem { Label("Presenze", systemImage: "checkmark.circle.fill") }
            NavigationStack { StaffMessagesView() }.tabItem { Label("Messaggi", systemImage: "bubble.left.and.bubble.right.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
        }
    }
}

private struct FamilyTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { FamilyCalendarView() }.tabItem { Label("Calendario", systemImage: "calendar") }
            NavigationStack { FamilyCoursesView() }.tabItem { Label("Corsi", systemImage: "figure.dance") }
            NavigationStack { FamilyDocumentsView() }.tabItem { Label("Documenti", systemImage: "doc.text.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
        }
    }
}

struct StaffCoursesView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        List(store.courses) { course in
            NavigationLink { CourseDetailView(courseID: course.id) } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(course.title).font(.headline)
                    Text("\(course.day) • \(course.time) • \(course.room)").font(.caption).foregroundColor(.secondary)
                    Text("\(course.enrolled) allievi").font(.caption.bold()).foregroundColor(.dzPurple)
                }.padding(.vertical, 5)
            }
        }.navigationTitle("Le mie lezioni")
    }
}

struct AttendanceRegisterView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedCourse = "Hip Hop Teen"
    @State private var showSaved = false

    private var visibleStudents: [Student] {
        let matches = store.students.filter { $0.course == selectedCourse }
        return matches.isEmpty ? store.students : matches
    }

    var body: some View {
        List {
            Section("Lezione selezionata") {
                Picker("Corso", selection: $selectedCourse) {
                    ForEach(store.courses.map(\.title), id: \.self) { Text($0) }
                }
                Label("Registro salvato automaticamente", systemImage: "checkmark.icloud.fill")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section("Registro") {
                ForEach(visibleStudents) { student in
                    Button {
                        store.toggleAttendance(studentID: student.id, courseTitle: selectedCourse)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(student.name).foregroundColor(.primary)
                                Text(student.course).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: store.isPresent(studentID: student.id, courseTitle: selectedCourse) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(store.isPresent(studentID: student.id, courseTitle: selectedCourse) ? .green : .secondary).font(.title3)
                        }
                    }
                }
            }
            Section {
                Button("Conferma registro") { store.saveLocalData(); showSaved = true }
            }
        }
        .navigationTitle("Presenze")
        .alert("Registro salvato", isPresented: $showSaved) { Button("OK", role: .cancel) {} }
    }
}

struct StaffMessagesView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        List {
            Section("Comunicazioni della scuola") {
                ForEach(store.announcements) { item in
                    VStack(alignment: .leading, spacing: 5) { Text(item.title).font(.headline); Text(item.body).font(.subheadline).foregroundColor(.secondary); Text(item.audience).font(.caption.bold()).foregroundColor(.dzPurple) }.padding(.vertical, 4)
                }
            }
            Section("Azioni") { Label("Scrivi alla segreteria", systemImage: "paperplane.fill"); Label("Avvisa il tuo corso", systemImage: "megaphone.fill") }
        }.navigationTitle("Messaggi")
    }
}

struct FamilyCalendarView: View {
    var body: some View {
        List {
            Section("Questa settimana") {
                FamilyLessonRow(day: "MAR", date: "14", title: "Danza Classica", time: "17:00 – 18:15", room: "Sala Étoile")
                FamilyLessonRow(day: "GIO", date: "16", title: "Danza Classica", time: "17:00 – 18:15", room: "Sala Étoile")
                FamilyLessonRow(day: "SAB", date: "18", title: "Prova saggio", time: "15:00 – 17:00", room: "Teatro")
            }
        }.navigationTitle("Calendario")
    }
}

private struct FamilyLessonRow: View {
    let day: String; let date: String; let title: String; let time: String; let room: String
    var body: some View { HStack(spacing: 14) { VStack { Text(day).font(.caption.bold()).foregroundColor(.dzPurple); Text(date).font(.title2.bold()) }.frame(width: 48); VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(time).font(.caption).foregroundColor(.secondary); Label(room, systemImage: "mappin.and.ellipse").font(.caption).foregroundColor(.secondary) }; Spacer() }.padding(.vertical, 6) }
}

struct FamilyCoursesView: View {
    var body: some View {
        ScrollView { VStack(spacing: 16) {
            DZCard { VStack(alignment: .leading, spacing: 12) { Label("Corso attivo", systemImage: "checkmark.seal.fill").foregroundColor(.green).font(.caption.bold()); Text("Danza Classica").font(.title2.bold()); Text("Insegnante: Giulia Ferri").foregroundColor(.secondary); Divider(); LabeledContent("Giorni", value: "Martedì e giovedì"); LabeledContent("Orario", value: "17:00"); LabeledContent("Sala", value: "Étoile") }.frame(maxWidth: .infinity, alignment: .leading) }
            DZCard { VStack(alignment: .leading, spacing: 10) { Text("Prossimo saggio").font(.headline); Text("Saggio d’estate • 28 giugno").font(.title3.bold()); Text("Costume confermato • Quota pagata").font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
        }.padding() }.background(ScreenBackground()).navigationTitle("I miei corsi")
    }
}

struct FamilyDocumentsView: View {
    var body: some View {
        List {
            Section("Certificato medico") { Label("Valido fino al 12/02/2027", systemImage: "checkmark.shield.fill").foregroundColor(.green); Label("Carica nuovo certificato", systemImage: "square.and.arrow.up") }
            Section("Pagamenti") { LabeledContent("Quota luglio", value: "Pagata"); LabeledContent("Saggio estivo", value: "Pagata"); Label("Storico ricevute", systemImage: "doc.text.magnifyingglass") }
            Section("Moduli") { Label("Regolamento scuola", systemImage: "doc.text.fill"); Label("Autorizzazione immagini", systemImage: "signature") }
        }.navigationTitle("Documenti")
    }
}

struct FamilyAttendanceView: View {
    var body: some View {
        List {
            Section("Riepilogo") { LabeledContent("Presenze", value: "24"); LabeledContent("Assenze", value: "1"); LabeledContent("Percentuale", value: "96%") }
            Section("Ultime lezioni") { Label("10 luglio • Presente", systemImage: "checkmark.circle.fill").foregroundColor(.green); Label("3 luglio • Presente", systemImage: "checkmark.circle.fill").foregroundColor(.green); Label("26 giugno • Assente", systemImage: "xmark.circle.fill").foregroundColor(.red) }
        }.navigationTitle("Le mie presenze")
    }
}

struct FamilyPaymentsView: View {
    var body: some View {
        List {
            Section("Situazione") { LabeledContent("Luglio", value: "Pagata"); LabeledContent("Importo", value: "€50,00"); LabeledContent("Metodo", value: "Bonifico") }
            Section("Ricevute") { Label("Ricevuta luglio 2026", systemImage: "doc.text.fill"); Label("Ricevuta giugno 2026", systemImage: "doc.text.fill") }
        }.navigationTitle("Quote e ricevute")
    }
}

struct FamilyMedicalView: View {
    var body: some View {
        List {
            Section("Certificato medico") { LabeledContent("Stato", value: "Valido"); LabeledContent("Scadenza", value: "18/11/2026") }
            Section("Documento") { Label("Visualizza certificato", systemImage: "doc.fill"); Label("Carica nuovo certificato", systemImage: "square.and.arrow.up.fill") }
        }.navigationTitle("Certificato")
    }
}
