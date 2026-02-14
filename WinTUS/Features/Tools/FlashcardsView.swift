import SwiftUI
import SwiftData

struct FlashcardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var flashcards: [Flashcard]
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    @State private var selectedSubjectID: PersistentIdentifier?
    @State private var showingAddCard = false
    @State private var showingRandomCardSheet = false
    @State private var cardToEdit: Flashcard?
    
    var filteredCards: [Flashcard] {
        if let subjectID = selectedSubjectID {
            return flashcards.filter { $0.subject?.persistentModelID == subjectID }
        }
        return flashcards
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
                
                // Kart Listesi
                if subjects.isEmpty {
                    ContentUnavailableView("Ders Bulunamadı", systemImage: "book.closed", description: Text("Önce ders ekleyiniz."))
                } else if filteredCards.isEmpty {
                    ContentUnavailableView("Kart Yok", systemImage: "rectangle.portrait.on.rectangle.portrait.slash", description: Text("Bu derse flashcard ekleyin."))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(filteredCards) { card in
                                FlashcardItemView(card: card)
                                    .contextMenu {
                                        Button("Düzenle", systemImage: "pencil") {
                                            cardToEdit = card
                                        }
                                        Button("Sil", systemImage: "trash", role: .destructive) {
                                            deleteCard(card)
                                        }
                                    }
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // FAB için boşluk
                    }
                }
            }
            
            // Floating Action Buttons (FAB)
            VStack(spacing: 16) {
                // Rastgele Kart
                Button {
                    showingRandomCardSheet = true
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 4)
                }
                .disabled(flashcards.isEmpty)
                
                // Ekle
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 4)
                }
            }
            .padding()
            .padding(.bottom, 90) // Custom TabBar'ın üstünde kalması için biraz daha yukarı
        }
        .navigationTitle("Flashcards")
        .sheet(isPresented: $showingAddCard) {
            AddFlashcardView()
        }
        .sheet(item: $cardToEdit) { card in
            AddFlashcardView(cardToEdit: card)
        }
        .sheet(isPresented: $showingRandomCardSheet) {
            RandomCardView(allCards: flashcards)
        }
        .onAppear {
            if selectedSubjectID == nil, let first = subjects.first {
                selectedSubjectID = first.persistentModelID
            }
        }
    }
    
    func deleteCard(_ card: Flashcard) {
        modelContext.delete(card)
    }
}

// MARK: - Components

struct SubjectTabButton: View {
    let title: String
    var colorHex: String = "#007AFF"
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color(hex: colorHex) : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct FlashcardItemView: View {
    let card: Flashcard
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Ön Yüz (Soru)
            CardFace(text: card.question, color: .blue, title: "Soru")
                .opacity(isFlipped ? 0 : 1)
            
            // Arka Yüz (Cevap)
            CardFace(text: card.answer, color: .green, title: "Cevap")
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 150)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
    }
}

struct CardFace: View {
    let text: String
    let color: Color
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(text)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Random Card Sheet with Flip Logic Fix
struct RandomCardView: View {
    let allCards: [Flashcard]
    @State private var currentCard: Flashcard?
    @State private var isFlipped = false // Cevabın açık olup olmadığını takip et
    
    var body: some View {
        VStack {
            Text("Rastgele Kart")
                .font(.headline)
                .padding(.top)
            
            if let card = currentCard {
                Spacer()
                
                // Tekil Kart Görünümü (Flip logic burada local)
                ZStack {
                    CardFace(text: card.question, color: .blue, title: "Soru")
                        .opacity(isFlipped ? 0 : 1)
                    
                    CardFace(text: card.answer, color: .green, title: "Cevap")
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(height: 300)
                .padding()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isFlipped.toggle()
                    }
                }
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                
                Spacer()
                
                Button("Başka Kart Çek 🎲") {
                    pickRandom()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            } else {
                Text("Gösterilecek kart yok.")
            }
        }
        .padding()
        .onAppear {
            pickRandom()
        }
    }
    
    func pickRandom() {
        // Yeni kart çekildiğinde flip durumunu sıfırla (Soruya dön)
        withAnimation(.none) { // Anlık geçiş
            isFlipped = false
        }
        // Kısa bir gecikmeyle kartı değiştir (Flip dönmesi bitince gibi hissettirmemek için, direkt soru gelsin)
        currentCard = allCards.randomElement()
    }
}

struct AddFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    var cardToEdit: Flashcard?
    
    @State private var question = ""
    @State private var answer = ""
    @State private var selectedSubject: Subject?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kart İçeriği") {
                    TextField("Soru", text: $question, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Cevap", text: $answer, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Ders") {
                    Picker("Ders", selection: $selectedSubject) {
                        Text("Ders Seçiniz").tag(nil as Subject?)
                        ForEach(subjects.sorted(by: { $0.name < $1.name })) { subject in
                            Text(subject.name).tag(subject as Subject?)
                        }
                    }
                }
            }
            .navigationTitle(cardToEdit == nil ? "Yeni Kart" : "Kartı Düzenle")
            .toolbar {
                Button("Kaydet") {
                    save()
                }
                .disabled(question.isEmpty || answer.isEmpty || selectedSubject == nil)
            }
            .onAppear {
                if let card = cardToEdit {
                    question = card.question
                    answer = card.answer
                    selectedSubject = card.subject
                }
            }
        }
    }
    
    func save() {
        if let card = cardToEdit {
            card.question = question
            card.answer = answer
            card.subject = selectedSubject
        } else {
            if let subject = selectedSubject {
                let newCard = Flashcard(question: question, answer: answer, subject: subject)
                modelContext.insert(newCard)
            }
        }
        dismiss()
    }
}
