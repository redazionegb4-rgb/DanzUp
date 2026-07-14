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
                    CourseDetailView(course: course)
                } label: {
                    CourseRow(course: course)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions {
                    Button(role: .destructive) {
                        store.courses.removeAll { $0.id == course.id }
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
    let course: DanceCourse
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
                ProgressView(value: Double(course.enrolled), total: Double(course.capacity)).tint(Color.dzPurple)
            }
            Spacer()
            Text("\(course.enrolled)/\(course.capacity)").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.vertical, 3)
    }
}

struct CourseDetailView: View {
    let course: DanceCourse
    var body: some View {
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
                        Label("\(course.enrolled) iscritti su \(course.capacity)", systemImage: "person.3.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                NavigationLink { OwnerAttendanceView() } label: { Text("Apri registro presenze").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dzPurple)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddCourseView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var teacher = ""
    @State private var day = "Lunedì"
    @State private var time = "17:00"
    @State private var room = "Sala 1"
    @State private var capacity = 20

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome corso", text: $title)
                    TextField("Insegnante", text: $teacher)
                    Picker("Giorno", selection: $day) {
                        ForEach(["Lunedì","Martedì","Mercoledì","Giovedì","Venerdì","Sabato"], id: \.self) { Text($0) }
                    }
                    TextField("Orario", text: $time)
                    TextField("Sala", text: $room)
                    Stepper("Capienza: \(capacity)", value: $capacity, in: 5...100)
                }
            }
            .navigationTitle("Nuovo corso")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        store.courses.append(DanceCourse(title: title.isEmpty ? "Nuovo corso" : title, teacher: teacher.isEmpty ? "Da assegnare" : teacher, day: day, time: time, room: room, enrolled: 0, capacity: capacity, style: "Danza"))
                        dismiss()
                    }
                }
            }
        }
    }
}
