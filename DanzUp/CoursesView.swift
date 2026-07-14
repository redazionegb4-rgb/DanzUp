import SwiftUI

struct CoursesView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var search = ""

    var filtered: [DanceCourse] {
        search.isEmpty ? store.courses : store.courses.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.teacher.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            ForEach(filtered) { course in
                NavigationLink {
                    CourseDetailView(courseID: course.id)
                } label: {
                    CourseRow(course: course)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions {
                    Button(role: .destructive) {
                        if let index = filtered.firstIndex(where: { $0.id == course.id }) {
                            store.deleteCourses(at: IndexSet(integer: index), from: filtered)
                        }
                    } label: { Label("Elimina", systemImage: "trash") }
                }
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Corsi")
        .searchable(text: $search, prompt: "Cerca corso o insegnante")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showAdd) { AddCourseView() }
    }
}

private struct CourseRow: View {
    @EnvironmentObject var store: AppStore
    let course: DanceCourse

    private var enrolled: Int { store.enrolledCount(for: course.id) }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.dance")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(BrandGradient())
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(course.title).font(.headline)
                Text("\(course.day) • \(course.time) • \(course.room)").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: Double(enrolled), total: Double(max(course.capacity, 1))).tint(Color.dzPurple)
            }
            Spacer()
            Text("\(enrolled)/\(course.capacity)").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.vertical, 3)
    }
}

struct CourseDetailView: View {
    @EnvironmentObject var store: AppStore
    let courseID: UUID

    private var course: DanceCourse? { store.courses.first { $0.id == courseID } }
    private var enrolledStudents: [Student] { store.studentsForCourse(courseID) }

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
                                Text("Allievi iscritti").font(.headline)
                                if enrolledStudents.isEmpty {
                                    VStack(spacing: 8) { Image(systemName: "person.crop.circle.badge.plus").font(.largeTitle).foregroundStyle(.secondary); Text("Nessun allievo").font(.headline); Text("Assegna gli allievi a questo corso dalla sezione Allievi.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 20)
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

                        NavigationLink { OwnerAttendanceView(initialCourseID: course.id) } label: {
                            Text("Apri registro presenze").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.dzPurple)
                        .controlSize(.large)
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(course.title)
                .navigationBarTitleDisplayMode(.inline)
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
