import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: FlashcardsView()) {
                        Label {
                            Text("Flashcards")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    NavigationLink(destination: NotesLibraryView()) {
                        Label {
                            Text("Not Kütüphanesi")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "photo.stack")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    NavigationLink(destination: TrialExamListView()) {
                        Label {
                            Text("Deneme Takibi")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Çalışma Araçları")
                }
                
                Section {
                    NavigationLink(destination: ResidencyGuideView()) {
                        Label {
                            Text("Uzmanlık Rehberi")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "building.columns.fill")
                                .foregroundStyle(.purple)
                        }
                    }
                } header: {
                    Text("TUS Rehberi")
                }
            }
            .navigationTitle("Araçlar")
        }
    }
}
