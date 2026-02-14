import SwiftUI

struct ResidencyGuideView: View {
    @State private var searchText = ""
    @State private var selectedDepartment: String?
    @State private var selectedCity: String?
    @State private var selectedPeriod: String?
    @State private var minScore = 45.0
    
    // Veri Yöneticisi
    let dataManager = ResidencyDataManager.shared
    
    // Filtrelenmiş Liste
    var filteredPrograms: [ResidencyProgram] {
        dataManager.programs.filter { program in
            let matchesSearch = searchText.isEmpty || 
                program.university.localizedCaseInsensitiveContains(searchText) ||
                program.hospital.localizedCaseInsensitiveContains(searchText) ||
                program.department.localizedCaseInsensitiveContains(searchText)
            
            let matchesCity = selectedCity == nil || program.city == selectedCity
            let matchesDepartment = selectedDepartment == nil || program.department == selectedDepartment
            let matchesPeriod = selectedPeriod == nil || program.period == selectedPeriod
            
            let matchesScore = program.minScore >= minScore
            
            return matchesSearch && matchesCity && matchesDepartment && matchesPeriod && matchesScore
        }.sorted { 
            // Önce döneme göre (yeni->eski), sonra puana göre (yüksek->düşük)
            if $0.period != $1.period {
                return $0.period > $1.period
            }
            return $0.minScore > $1.minScore 
        }
    }
    
    // Benzersiz Şehirler
    var cities: [String] {
        Array(Set(dataManager.programs.map { $0.city })).sorted()
    }
    
    // Benzersiz Bölümler
    var departments: [String] {
        Array(Set(dataManager.programs.map { $0.department })).sorted()
    }
    
    // Benzersiz Dönemler
    var periods: [String] {
        Array(Set(dataManager.programs.map { $0.period })).sorted(by: >)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtreleme Alanı
                VStack(alignment: .leading, spacing: 12) {
                    // Bölüm Filtresi
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Text("Bölüm:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button(action: { selectedDepartment = nil }) {
                                Text("Tümü")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedDepartment == nil ? Color.purple : Color(.systemGray5))
                                    .foregroundStyle(selectedDepartment == nil ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(departments, id: \.self) { department in
                                Button(action: { selectedDepartment = department }) {
                                    Text(department)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedDepartment == department ? Color.purple : Color(.systemGray5))
                                        .foregroundStyle(selectedDepartment == department ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Şehir Filtresi
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Text("Şehir:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button(action: { selectedCity = nil }) {
                                Text("Tümü")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCity == nil ? Color.blue : Color(.systemGray5))
                                    .foregroundStyle(selectedCity == nil ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(cities, id: \.self) { city in
                                Button(action: { selectedCity = city }) {
                                    Text(city)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCity == city ? Color.blue : Color(.systemGray5))
                                        .foregroundStyle(selectedCity == city ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Dönem Filtresi
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Text("Dönem:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button(action: { selectedPeriod = nil }) {
                                Text("Tümü")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedPeriod == nil ? Color.green : Color(.systemGray5))
                                    .foregroundStyle(selectedPeriod == nil ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(periods, id: \.self) { period in
                                Button(action: { selectedPeriod = period }) {
                                    Text(period)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedPeriod == period ? Color.green : Color(.systemGray5))
                                        .foregroundStyle(selectedPeriod == period ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    HStack {
                        Text("Min Puan: \(String(format: "%.1f", minScore))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(value: $minScore, in: 45...85, step: 0.5)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(uiColor: .secondarySystemBackground))
                
                // Liste
                List(filteredPrograms) { program in
                    NavigationLink(destination: ResidencyDetailView(program: program)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(program.department)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(program.institution) // University/Hospital
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                
                                HStack(spacing: 6) {
                                    Text(program.city)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundStyle(.orange)
                                        .cornerRadius(4)
                                    
                                    Text(program.type)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundStyle(.purple)
                                        .cornerRadius(4)
                                        
                                    Text(program.period)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundStyle(.green)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(String(format: "%.2f", program.minScore))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                
                                Text("Kon: \(program.quota)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Uzmanlık Rehberi")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Bölüm veya Hastane ara...")
            .overlay {
                if filteredPrograms.isEmpty {
                    ContentUnavailableView("Program Bulunamadı", systemImage: "magnifyingglass", description: Text("Filtreleri değiştirerek tekrar deneyin."))
                }
            }
        }
    }
}

struct ResidencyDetailView: View {
    let program: ResidencyProgram
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Başlık Kartı
                VStack(spacing: 16) {
                    Text(program.department)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(program.institution)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Label(program.city, systemImage: "map.fill")
                        Divider()
                        Label(program.type, systemImage: "building.2.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // İstatistik Kartları
                HStack(spacing: 16) {
                    StatCard(title: "Taban Puan", value: String(format: "%.2f", program.minScore), icon: "chart.bar.fill", color: .blue)
                    StatCard(title: "Kontenjan", value: "\(program.quota)", icon: "person.2.fill", color: .green)
                }
                .padding(.horizontal)
                
                // Bilgi Notu
                VStack(alignment: .leading, spacing: 12) {
                    Label("Bilgi", systemImage: "info.circle")
                        .font(.headline)
                    
                    Text("Bu veriler 2024 TUS (Son Yerleştirme) sonuçlarına göre yaklaşık değerlerdir. TUS puan hesaplaması ve kontenjanlar her dönem değişiklik gösterebilir. Kesin bilgi için ÖSYM kılavuzunu kontrol ediniz.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Program Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .systemGray5), lineWidth: 1)
        )
    }
}
