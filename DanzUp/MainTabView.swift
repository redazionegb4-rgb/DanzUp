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
    private var visibleLessons: [CourseLesson] { store.lessonsForCurrentStaff() }
    var body: some View {
        List {
            Section { DZListHero(title: "Le mie lezioni", subtitle: "Agenda, classi e registro in un solo tocco", icon: "figure.dance", accent: .dzPurple) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            ForEach(visibleLessons) { lesson in
                NavigationLink { LessonAttendanceView(lesson: lesson) } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.courses.first(where: { $0.id == lesson.courseID })?.title ?? "Corso").font(.headline)
                        Text(lesson.start.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
                        Text("\(store.studentsForCourse(lesson.courseID).count) allievi • \(lesson.room)").font(.caption.bold()).foregroundColor(.dzPurple)
                    }.padding(.vertical, 5)
                }
            }
        }.modernScreen().navigationTitle("Le mie lezioni")
    }
}

struct AttendanceRegisterView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        List {
            Section { DZListHero(title: "Registro presenze", subtitle: "Compila e controlla ogni lezione assegnata", icon: "checkmark.circle.fill", accent: .dzMint) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            Section("Lezioni") {
                ForEach(store.lessonsForCurrentStaff()) { lesson in
                    NavigationLink { LessonAttendanceView(lesson: lesson) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.courses.first(where: { $0.id == lesson.courseID })?.title ?? "Corso").font(.headline)
                            Text(lesson.start.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
                            Text(lesson.state.rawValue).font(.caption.bold()).foregroundColor(.dzPurple)
                        }
                    }
                }
            }
        }.modernScreen().navigationTitle("Presenze")
    }
}

struct StaffMessagesView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        List {
            Section { DZListHero(title: "Messaggi", subtitle: "Comunicazioni della scuola e avvisi ai corsi", icon: "bubble.left.and.bubble.right.fill", accent: .dzFuchsia) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            Section("Comunicazioni della scuola") {
                ForEach(store.announcements) { item in
                    VStack(alignment: .leading, spacing: 5) { Text(item.title).font(.headline); Text(item.body).font(.subheadline).foregroundColor(.secondary); Text(item.audience).font(.caption.bold()).foregroundColor(.dzPurple) }.padding(.vertical, 4)
                }
            }
            Section("Azioni") { Label("Scrivi alla segreteria", systemImage: "paperplane.fill"); Label("Avvisa il tuo corso", systemImage: "megaphone.fill") }
        }.modernScreen().navigationTitle("Messaggi")
    }
}

struct FamilyCalendarView: View {
    @EnvironmentObject var store: AppStore
    private var children: [Student] { store.userRole == .parent ? store.linkedChildrenForCurrentParent() : Array(store.students.prefix(1)) }
    private var lessons: [CourseLesson] { children.flatMap { store.lessonsForStudent($0.id) }.sorted { $0.start < $1.start } }
    var body: some View {
        List {
            Section { DZListHero(title: "Calendario", subtitle: "Lezioni, prove ed eventi dei profili collegati", icon: "calendar", accent: .dzSky) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            Section("Calendario reale") {
                if lessons.isEmpty { Text("Nessuna lezione programmata").foregroundColor(.secondary) }
                ForEach(lessons) { lesson in
                    FamilyLessonRow(day: lesson.start.formatted(.dateTime.weekday(.abbreviated)).uppercased(), date: lesson.start.formatted(.dateTime.day()), title: store.courses.first(where: { $0.id == lesson.courseID })?.title ?? "Corso", time: lesson.start.formatted(date: .omitted, time: .shortened), room: lesson.room)
                }
            }
            Section("Eventi") {
                ForEach(store.danceEvents) { event in Label("\(event.title) • \(event.date.formatted(date: .abbreviated, time: .shortened))", systemImage: "star.fill") }
            }
        }.modernScreen().navigationTitle("Calendario")
    }
}

private struct FamilyLessonRow: View {
    let day: String; let date: String; let title: String; let time: String; let room: String
    var body: some View { HStack(spacing: 14) { VStack { Text(day).font(.caption.bold()).foregroundColor(.dzPurple); Text(date).font(.title2.bold()) }.frame(width: 48); VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(time).font(.caption).foregroundColor(.secondary); Label(room, systemImage: "mappin.and.ellipse").font(.caption).foregroundColor(.secondary) }; Spacer() }.padding(.vertical, 6) }
}

struct FamilyCoursesView: View {
    @EnvironmentObject var store: AppStore

    private var visibleChildren: [Student] {
        if store.userRole == .parent {
            return store.linkedChildrenForCurrentParent()
        }
        // In modalità demo allievo mostriamo il profilo dimostrativo; con account reali
        // il database collegherà direttamente l’account allo studentID corretto.
        return Array(store.students.prefix(1))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if visibleChildren.isEmpty {
                    DZCard {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 42))
                                .foregroundColor(.dzPurple)
                            Text("Nessun figlio collegato").font(.headline)
                            Text("Collega un figlio dal Profilo usando il codice personale fornito dalla scuola.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(visibleChildren) { child in
                        let childCourses = store.coursesForStudent(child.id)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(child.name).font(.title3.bold())
                                    Text(childCourses.count == 1 ? "1 corso frequentato" : "\(childCourses.count) corsi frequentati")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(childCourses.count)")
                                    .font(.title2.bold())
                                    .foregroundColor(.dzPurple)
                            }
                            .padding(.horizontal, 4)

                            if childCourses.isEmpty {
                                DZCard {
                                    Label("Nessun corso assegnato", systemImage: "figure.dance")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                ForEach(childCourses) { course in
                                    NavigationLink {
                                        FamilyCourseDetailView(course: course, child: child)
                                    } label: {
                                        DZCard {
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(course.title).font(.headline).foregroundColor(.primary)
                                                        Text(course.style).font(.caption.bold()).foregroundColor(.dzPurple)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.secondary)
                                                }
                                                Divider()
                                                Label("\(course.day) • \(course.time)", systemImage: "calendar")
                                                    .font(.subheadline).foregroundColor(.secondary)
                                                Label(course.room, systemImage: "mappin.and.ellipse")
                                                    .font(.subheadline).foregroundColor(.secondary)
                                                Label(course.teacher, systemImage: "person.fill")
                                                    .font(.subheadline).foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                DZCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prossimo saggio").font(.headline)
                        Text("Saggio d’estate • 28 giugno").font(.title3.bold())
                        Text("Costume confermato • Quota pagata").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(ScreenBackground())
        .navigationTitle("I miei corsi")
    }
}

private struct FamilyCourseDetailView: View {
    let course: DanceCourse
    let child: Student

    var body: some View {
        List {
            Section { DZListHero(title: course.title, subtitle: "Dettagli, calendario e situazione di \(child.name)", icon: "figure.dance", accent: .dzPurple) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            Section("Allievo") {
                LabeledContent("Nome", value: child.name)
                LabeledContent("Stato", value: "Iscritto")
            }
            Section("Corso") {
                LabeledContent("Disciplina", value: course.title)
                LabeledContent("Stile", value: course.style)
                LabeledContent("Giorno", value: course.day)
                LabeledContent("Orario", value: course.time)
                LabeledContent("Sala", value: course.room)
                LabeledContent("Insegnante", value: course.teacher)
            }
            Section("Collegamenti") {
                NavigationLink("Calendario del corso") { FamilyCalendarView() }
                NavigationLink("Presenze") { FamilyAttendanceView() }
                NavigationLink("Quote e ricevute") { FamilyPaymentsView() }
            }
        }
        .modernScreen()
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FamilyDocumentsView: View {
    @EnvironmentObject var store: AppStore
    private var children: [Student] { store.userRole == .parent ? store.linkedChildrenForCurrentParent() : Array(store.students.prefix(1)) }
    var body: some View {
        List {
            Section { DZListHero(title: "Documenti", subtitle: "Certificati, allegati, quote e ricevute", icon: "doc.text.fill", accent: .dzOrange) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            ForEach(children) { child in
                Section(child.name) {
                    ForEach(store.documentsForStudent(child.id)) { document in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text(document.title).font(.headline); Spacer(); Text(document.reviewStatus.rawValue).font(.caption.bold()).foregroundColor(.dzPurple) }
                            if let expiry = document.expiryDate { Text("Scadenza \(expiry.formatted(date: .numeric, time: .omitted))").font(.caption).foregroundColor(.secondary) }
                            Label(document.hasAttachment ? "Allegato caricato" : "Allegato da caricare", systemImage: document.hasAttachment ? "doc.fill" : "square.and.arrow.up").font(.caption)
                        }.padding(.vertical, 3)
                    }
                    ForEach(store.paymentsForStudent(child.id)) { payment in
                        HStack { Label(payment.title, systemImage: "eurosign.circle.fill"); Spacer(); Text(payment.status.rawValue).font(.caption.bold()).foregroundColor(payment.status.color) }
                    }
                }
            }
        }.modernScreen().navigationTitle("Documenti")
    }
}

struct FamilyAttendanceView: View {
    @EnvironmentObject var store: AppStore
    private var child: Student? { store.userRole == .parent ? store.linkedChildrenForCurrentParent().first : store.students.first }
    var body: some View {
        List {
            Section { DZListHero(title: "Presenze", subtitle: "Storico aggiornato delle lezioni frequentate", icon: "chart.bar.fill", accent: .dzMint) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            if let child {
                Section("Storico di \(child.name)") {
                    let records = store.attendanceForStudent(child.id)
                    if records.isEmpty { Text("Nessuna presenza registrata").foregroundColor(.secondary) }
                    ForEach(records) { record in
                        HStack { Text(store.lessons.first(where: { $0.id == record.lessonID })?.start.formatted(date: .abbreviated, time: .shortened) ?? "Lezione"); Spacer(); Text(record.state.rawValue).foregroundColor(record.state == .present ? .green : .orange) }
                    }
                }
            }
        }.modernScreen().navigationTitle("Le mie presenze")
    }
}

struct FamilyPaymentsView: View {
    @EnvironmentObject var store: AppStore
    private var child: Student? { store.userRole == .parent ? store.linkedChildrenForCurrentParent().first : store.students.first }
    var body: some View {
        List {
            Section { DZListHero(title: "Quote e ricevute", subtitle: "Pagamenti, scadenze e stato delle quote", icon: "eurosign.circle.fill", accent: .dzOrange) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            if let child {
                Section(child.name) {
                    ForEach(store.paymentsForStudent(child.id)) { payment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text(payment.title).font(.headline); Spacer(); Text(payment.status.rawValue).font(.caption.bold()).foregroundColor(payment.status.color) }
                            Text("€\(payment.paidAmount, specifier: "%.2f") / €\(payment.amount, specifier: "%.2f")").font(.caption).foregroundColor(.secondary)
                            Text("Scadenza \(payment.dueDate.formatted(date: .numeric, time: .omitted)) • \(payment.method)").font(.caption).foregroundColor(.secondary)
                        }.padding(.vertical, 3)
                    }
                }
            }
        }.modernScreen().navigationTitle("Quote e ricevute")
    }
}

struct FamilyMedicalView: View {
    var body: some View {
        List {
            Section { DZListHero(title: "Certificato medico", subtitle: "Stato, scadenza e caricamento documento", icon: "cross.case.fill", accent: .dzSky) }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            Section("Certificato medico") { LabeledContent("Stato", value: "Valido"); LabeledContent("Scadenza", value: "18/11/2026") }
            Section("Documento") { Label("Visualizza certificato", systemImage: "doc.fill"); Label("Carica nuovo certificato", systemImage: "square.and.arrow.up.fill") }
        }.modernScreen().navigationTitle("Certificato")
    }
}
