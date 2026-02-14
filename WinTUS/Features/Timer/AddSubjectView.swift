import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedColorHex: String = "#FF5733"
    
    let availableColors = [
        "#FF5733", // Turuncu
        "#33FF57", // Yeşil
        "#3357FF", // Mavi
        "#FF33F5", // Pembe
        "#33FFF5", // Turkuaz
        "#F5FF33", // Sarı
        "#8E44AD", // Mor
        "#E74C3C"  // Kırmızı
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ders Bilgileri") {
                    TextField("Ders Adı (Örn: Anatomi)", text: $name)
                }
                
                Section("Renk Seçimi") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .bold()
                                    }
                                }
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Yeni Ders Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveSubject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(name: name, colorHex: selectedColorHex)
        modelContext.insert(newSubject)
        dismiss()
    }
}

#Preview {
    AddSubjectView()
}
