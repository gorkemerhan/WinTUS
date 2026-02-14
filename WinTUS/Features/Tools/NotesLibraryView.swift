import SwiftUI
import SwiftData
import PhotosUI

struct NotesLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [StudyNote]
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    @State private var selectedSubjectID: PersistentIdentifier?
    @State private var showingAddNote = false
    @State private var showingRandomNote = false
    
    var filteredNotes: [StudyNote] {
        if let subjectID = selectedSubjectID {
            return notes.filter { $0.subject?.persistentModelID == subjectID }
        }
        return notes
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Üst Sekmeler (Subject Tabs)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subjects) { subject in
                            SubjectTabButton(
                                title: subject.name,
                                colorHex: subject.colorHex,
                                isSelected: selectedSubjectID == subject.persistentModelID
                            ) {
                                selectedSubjectID = subject.persistentModelID
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
                
                // Not Listesi
                if subjects.isEmpty {
                    ContentUnavailableView("Ders Bulunamadı", systemImage: "book.closed", description: Text("Ders ekleyerek başlayın."))
                } else if filteredNotes.isEmpty {
                    ContentUnavailableView("Not Yok", systemImage: "note.text", description: Text("Bu ders için not ekleyin."))
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note)) {
                                HStack {
                                    if let data = note.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                            .overlay(Image(systemName: "text.justify.left").foregroundStyle(.secondary))
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(note.title)
                                            .font(.headline)
                                        Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteNote)
                    }
                    .listStyle(.plain)
                    .padding(.bottom, 80)
                }
            }
            
            // FAB Buttons
            VStack(spacing: 16) {
                // Rastgele Not
                Button {
                    showingRandomNote = true
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 4)
                }
                .disabled(notes.isEmpty)
                
                // Ekle
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 4)
                }
            }
            .padding()
            .padding(.bottom, 90)
        }
        .navigationTitle("Not Kütüphanesi")
        .sheet(isPresented: $showingAddNote) {
            AddNoteView()
        }
        .sheet(isPresented: $showingRandomNote) {
            if let randomNote = notes.randomElement() {
                 RandomNoteDetailSheet(note: randomNote)
            }
        }
        .onAppear {
            if selectedSubjectID == nil, let first = subjects.first {
                selectedSubjectID = first.persistentModelID
            }
        }
    }
    
    func deleteNote(at offsets: IndexSet) {
        let notesToDelete = offsets.map { filteredNotes[$0] }
        for note in notesToDelete {
            modelContext.delete(note)
        }
    }
}

// MARK: - Random Note Sheet
struct RandomNoteDetailSheet: View {
    @State var note: StudyNote 
    @Query private var allNotes: [StudyNote]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            NoteDetailView(note: note)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Başka Not Getir 🎲") {
                            if let newRandom = allNotes.randomElement() {
                                note = newRandom
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Note Detail View (Full Screen Image & Zoom or Just Text)
struct NoteDetailView: View {
    let note: StudyNote
    @State private var isZoomed = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let data = note.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .onTapGesture {
                            isZoomed = true
                        }
                        .fullScreenCover(isPresented: $isZoomed) {
                            FullScreenImageView(image: uiImage)
                        }
                } else {
                    // Resim yoksa placeholder veya sadece metin
                    HStack {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary.opacity(0.3))
                        Spacer()
                    }
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(note.title)
                        .font(.title2)
                        .bold()
                    
                    if let subject = note.subject {
                        Text(subject.name)
                            .font(.subheadline)
                            .padding(6)
                            .background(Color(hex: subject.colorHex).opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Text("Eklenme: \(note.createdAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Not Detayı")
    }
}

// MARK: - Add Note View (Optional Image)
struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    @State private var title = ""
    @State private var selectedSubject: Subject?
    
    // Image Handling
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingSourceConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Not Bilgileri") {
                    TextField("Başlık (Notunu buraya yaz)", text: $title, axis: .vertical)
                        .lineLimit(3...10) // Textarea gibi davranması için
                    
                    Picker("Ders", selection: $selectedSubject) {
                        Text("Ders Seçiniz").tag(nil as Subject?)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject as Subject?)
                        }
                    }
                }
                
                Section("Görsel (İsteğe Bağlı)") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        Button("Fotoğrafı Değiştir") {
                            showingSourceConfirmation = true
                        }
                        .foregroundStyle(.blue)
                        
                        Button("Fotoğrafı Kaldır", role: .destructive) {
                            selectedImage = nil
                        }
                    } else {
                        Button {
                            showingSourceConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                Text("Fotoğraf Ekle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yeni Not")
            .toolbar {
                Button("Kaydet") {
                    saveNote()
                }
                .disabled(title.isEmpty || selectedSubject == nil)
            }
            .confirmationDialog("Fotoğraf Kaynağı", isPresented: $showingSourceConfirmation, titleVisibility: .visible) {
                Button("Kamera") {
                    sourceType = .camera
                    showingImagePicker = true
                }
                Button("Galeri") {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("İptal", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
                    .ignoresSafeArea()
            }
        }
    }
    
    func saveNote() {
        guard let subject = selectedSubject else { return }
        
        var imageData: Data? = nil
        if let image = selectedImage {
            imageData = image.jpegData(compressionQuality: 0.7)
        }
        
        let note = StudyNote(title: title, imageData: imageData, subject: subject)
        modelContext.insert(note)
        dismiss()
    }
}

// MARK: - Full Screen Zoomable Image
struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(currentScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            currentScale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if currentScale < 1.0 {
                                withAnimation {
                                    currentScale = 1.0
                                }
                            }
                        }
                )
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

// MARK: - UIKit Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
