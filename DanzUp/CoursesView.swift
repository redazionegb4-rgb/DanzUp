import SwiftUI

struct CoursesView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var showAdd = false

    private var filtered: [DanceCourse] {
        search.isEmpty ? store.courses : store.courses.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            $0.teacher.localizedCaseInsensitiveContains(search) ||
            $0.style.localizedCaseInsensitiveContains(search)
        }
    }

    private var totalEnrolled: Int { store.courses.reduce(0) { $0 + store.enrolledCount(for: $1.id) } }
    private var availablePlaces: Int { store.courses.reduce(0) { $0 + max(0, $1.capacity - store.enrolledCount(for: $1.id)) } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScreenBackground()
            ScrollView {
                LazyVStack(spacing: 18) {
                    DZHeroHeader(
                        eyebrow: "Programmazione",
                        title: "Corsi",
                        subtitle: "Orari, insegnanti, sale e iscritti con una vista più chiara.",
                        systemImage: "figure.dance",
                        accent: .dzFuchsia
                    )

                    HStack(spacing: 10) {
                        DZMetricTile(value: "\(store.courses.count)", label: "Corsi attivi", icon: "rectangle.stack.fill", color: .dzFuchsia)
                        DZMetricTile(value: "\(totalEnrolled)", label: "Iscrizioni", icon: "person.3.fill", color: .dzPurple)
                        DZMetricTile(value: "\(availablePlaces)", label: "Posti liberi", icon: "chair.fill", color: .dzMint)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Cerca corso, stile o insegnante", text: $search)
                        if !search.isEmpty {
                            Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.primary.opacity(0.06)))

                    if filtered.isEmpty {
                        DZCard {
                            DZEmptyState(
                                icon: "figure.dance",
                                title: search.isEmpty ? "Nessun corso" : "Nessun risultato",
                                message: search.isEmpty ? "Crea il primo corso, scegli orario e sala e poi assegna allievi e insegnanti." : "Prova a modificare la ricerca.",
                                actionTitle: search.isEmpty ? "Crea corso" : nil,
                                action: search.isEmpty ? { showAdd = true } : nil
                            )
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, course in
                                NavigationLink { CourseDetailView(courseID: course.id) } label: {
                                    CourseModernCard(course: course, index: index)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if let row = filtered.firstIndex(where: { $0.id == course.id }) {
                                            store.deleteCourses(at: IndexSet(integer: row), from: filtered)
                                        }
                                    } label: { Label("Elimina", systemImage: "trash") }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            DZFloatingAddButton { showAdd = true }.padding(22)
        }
        .navigationTitle("Corsi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddCourseView() }
    }
}

private struct CourseModernCard: View {
    @EnvironmentObject var store: AppStore
    let course: DanceCourse
    let index: Int

    private var enrolled: Int { store.enrolledCount(for: course.id) }
    private var progress: Double { Double(enrolled) / Double(max(course.capacity, 1)) }
    private var accent: Color {
        [Color.dzPurple, .dzFuchsia, .dzSky, .dzMint, .dzOrange][index % 5]
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color.dzNavy, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color.white.opacity(0.11)).frame(width: 110, height: 110).offset(x: 255, y: -28)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(course.style.uppercased())
                            .font(.caption2.weight(.heavy)).tracking(1.1).foregroundStyle(.white.opacity(0.7))
                        Text(course.title)
                            .font(.title3.weight(.heavy)).foregroundStyle(.white)
                        Text(course.teacher.isEmpty ? "Insegnante da assegnare" : course.teacher)
                            .font(.caption).foregroundStyle(.white.opacity(0.78))
                    }
                    Spacer()
                    Image(systemName: "figure.dance")
                        .font(.system(size: 32, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                }
                .padding(18)
            }
            .frame(height: 128)

            VStack(spacing: 13) {
                HStack(spacing: 18) {
                    Label(course.day, systemImage: "calendar").lineLimit(1)
                    Label(course.time, systemImage: "clock.fill")
                    Label(course.room, systemImage: "door.left.hand.open").lineLimit(1)
                    Spacer(minLength: 0)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Capienza").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(enrolled) / \(course.capacity)").font(.caption.bold())
                        }
                        ProgressView(value: progress).tint(accent)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.bold()).foregroundStyle(.tertiary).padding(.leading, 5)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.primary.opacity(0.05)))
        .shadow(color: accent.opacity(0.13), radius: 18, y: 9)
    }
}

struct CourseDetailView: View {
    @EnvironmentObject var store: AppStore
    let courseID: UUID
    @State private var showManageStudents = false
    @State private var showManageTeachers = false

    private var course: DanceCourse? { store.courses.first { $0.id == courseID } }
    private var enrolledStudents: [Student] { store.studentsForCourse(courseID) }
    private var assignedTeachers: [SchoolMember] { store.assignedTeachers(for: courseID) }

    var body: some View {
        Group {
            if let course {
                ScrollView {
                    VStack(spacing: 18) {
                        ZStack {
                            BrandGradient()
                            Image(systemName: "figure.dance").font(.system(size: 64)).foregroundStyle(.white.opacity(0.95))
                        }
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                        DZCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(course.title).font(.title2.bold())
                                Label(course.teacher, systemImage: "person.fill")
                                Label("\(course.day) alle \(course.time)", systemImage: "calendar")
                                Label(course.room, systemImage: "door.left.hand.open")
                                Label("\(enrolledStudents.count) iscritti su \(course.capacity)", systemImage: "person.3.fill")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        DZCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Insegnanti assegnati").font(.headline)
                                    Spacer()
                                    Button("Gestisci") { showManageTeachers = true }
                                        .font(.subheadline.bold())
                                }
                                if assignedTeachers.isEmpty {
                                    Text("Nessun insegnante assegnato")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(assignedTeachers) { teacher in
                                        HStack(spacing: 10) {
                                            Image(systemName: "person.crop.circle.fill")
                                                .foregroundStyle(Color.dzPurple)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(teacher.name)
                                                Text(teacher.email).font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        DZCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Allievi iscritti").font(.headline)
                                if enrolledStudents.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text("Nessun allievo")
                                            .font(.headline)
                                        Text("Usa Gestisci iscritti per aggiungere gli allievi direttamente a questo corso.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    ForEach(enrolledStudents) { student in
                                        HStack {
                                            Image(systemName: "person.crop.circle.fill").foregroundStyle(Color.dzPurple)
                                            Text(student.name)
                                            Spacer()
                                            Text("\(student.age) anni").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            showManageStudents = true
                        } label: {
                            Label("Gestisci iscritti", systemImage: "person.3.sequence.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.dzPurple)
                        .controlSize(.large)

                        NavigationLink { OwnerAttendanceView(initialCourseID: course.id) } label: {
                            Label("Apri registro presenze", systemImage: "checklist")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.dzPurple)
                        .controlSize(.large)
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(course.title)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showManageStudents) {
                    ManageCourseStudentsView(courseID: course.id)
                }
                .sheet(isPresented: $showManageTeachers) {
                    ManageCourseTeachersView(courseID: course.id)
                }
            } else {
                VStack(spacing: 10) { Image(systemName: "exclamationmark.triangle").font(.largeTitle); Text("Corso non disponibile").font(.headline) }.foregroundStyle(.secondary)
            }
        }
    }
}

struct AddCourseView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var teacher = ""
    @State private var day = "Lunedì"
    @State private var lessonTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @State private var room = "Sala 1"
    @State private var capacity = 20

    private var formattedTime: String {
        lessonTime.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome corso", text: $title)
                    TextField("Insegnante", text: $teacher)
                    Picker("Giorno", selection: $day) {
                        ForEach(["Lunedì","Martedì","Mercoledì","Giovedì","Venerdì","Sabato","Domenica"], id: \.self) { Text($0) }
                    }
                    DatePicker("Orario", selection: $lessonTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                    TextField("Sala", text: $room)
                    Stepper("Capienza: \(capacity)", value: $capacity, in: 5...100)
                }
            }
            .navigationTitle("Nuovo corso")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        store.addCourse(DanceCourse(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nuovo corso" : title,
                            teacher: teacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Da assegnare" : teacher,
                            day: day,
                            time: formattedTime,
                            room: room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sala 1" : room,
                            enrolled: 0,
                            capacity: capacity,
                            style: "Danza"
                        ))
                        dismiss()
                    }
                }
            }
        }
    }
}


struct ManageCourseStudentsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let courseID: UUID
    @State private var search = ""

    private var course: DanceCourse? {
        store.courses.first { $0.id == courseID }
    }

    private var filteredStudents: [Student] {
        let sorted = store.students.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.course.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let course {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.dance")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(BrandGradient())
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(course.title).font(.headline)
                                Text("\(store.enrolledCount(for: courseID)) iscritti su \(course.capacity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section {
                        if filteredStudents.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("Nessun allievo").font(.headline)
                                Text("Crea prima un allievo dalla sezione Allievi.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(filteredStudents) { student in
                                let isEnrolled = store.isStudent(student.id, enrolledIn: courseID)
                                Button {
                                    if isEnrolled {
                                        store.removeStudent(student.id, fromCourseID: courseID)
                                    } else {
                                        store.assignStudent(student.id, toCourseID: courseID)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isEnrolled ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(isEnrolled ? Color.dzPurple : Color.secondary)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(student.name)
                                                .foregroundStyle(.primary)
                                            Text(isEnrolled ? "Iscritto a questo corso" : store.coursesForStudent(student.id).isEmpty ? "Nessun corso" : "Già in \(store.coursesForStudent(student.id).count) corsi")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if !isEnrolled && !store.coursesForStudent(student.id).isEmpty {
                                            Text("Aggiungi")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.dzPurple)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Tutti gli allievi")
                    } footer: {
                        Text("Ogni allievo può essere iscritto a più corsi. La selezione aggiunge o rimuove soltanto questo corso.")
                    }
                }
            }
            .navigationTitle("Gestisci iscritti")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Cerca allievo")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
    }
}


struct ManageCourseTeachersView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let courseID: UUID
    @State private var search = ""

    private var teachers: [SchoolMember] {
        let values = store.schoolMembers.filter { $0.role == .teacher && $0.isActive }
        guard !search.isEmpty else { return values }
        return values.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.email.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if teachers.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Nessun insegnante disponibile").font(.headline)
                            Text("Crea prima un accesso insegnante dalla sezione Inviti e codici.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(teachers) { teacher in
                            let selected = store.assignedTeachers(for: courseID).contains(where: { $0.id == teacher.id })
                            Button {
                                store.toggleTeacher(teacher.id, for: courseID)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selected ? Color.dzPurple : Color.secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(teacher.name).foregroundStyle(.primary)
                                        Text(teacher.email).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Insegnanti")
                } footer: {
                    Text("Puoi assegnare più insegnanti allo stesso corso. Gli insegnanti vedranno soltanto i corsi loro assegnati.")
                }
            }
            .navigationTitle("Assegna insegnanti")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Cerca insegnante")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fine") { dismiss() } }
            }
        }
    }
}
