import json

def generate_swift_code():
    json_path = "/Users/gorkem/WinTus/WinTUS/Resources/residency_data.json"
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: JSON file not found at {json_path}")
        return

    # Helper function for robust string sanitization
    def clean_str(s):
        if not s: return ""
        try:
            import json
            # JSON dumps escapes complex characters safely
            dumped = json.dumps(s, ensure_ascii=False)
            # Remove surrounding quotes to embed in Swift string
            return dumped[1:-1]
        except:
            return ""

    swift_code = """import Foundation

// Bu dosya otomatik oluşturulmuştur.
// 5000+ satır veri içerdiği için "Compiler unable to type-check" hatasını önlemek amacıyla
// veriler parçalı (batch) olarak yüklenmektedir.

extension ResidencyDataManager {
"""

    # Batching logic
    chunk_size = 500
    chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
    
    batch_names = []

    for i, chunk in enumerate(chunks):
        batch_name = f"batch{i}"
        batch_names.append(batch_name)
        
        swift_code += f"    private static let {batch_name}: [ResidencyProgram] = [\n"
        
        for item in chunk:
            institution = clean_str(item.get('institution', ''))
            department = clean_str(item.get('department', ''))
            city = clean_str(item.get('city', ''))
            type_ = clean_str(item.get('type', ''))
            period = clean_str(item.get('period', ''))
            quota = item.get('quota', 0)
            minScore = item.get('minScore', 0.0)
            
            # Using 'institution' for both university and hospital
            # Note: We depend on ResidencyProgram having 'university' and 'hospital' properties.
            # 'institution' computed property was added to the struct manually to handle UI.
            
            swift_code += f"""        ResidencyProgram(
            university: "{institution}", 
            hospital: "{institution}", 
            department: "{department}", 
            city: "{city}", 
            type: "{type_}", 
            quota: {quota}, 
            minScore: {minScore}, 
            scoreType: "K",
            period: "{period}"
        ),
"""
        swift_code += "    ]\n\n"

    # Combine batches
    swift_code += "    static let generatedPrograms: [ResidencyProgram] = "
    if batch_names:
        swift_code += " + ".join(batch_names)
    else:
        swift_code += "[]"
        
    swift_code += "\n}\n"

    output_path = "/Users/gorkem/WinTus/WinTUS/Data/ResidencyDataLoader.swift"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(swift_code)
    print(f"Generated Swift code at {output_path}")

if __name__ == "__main__":
    generate_swift_code()
