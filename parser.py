import csv
import json
import glob
import os
import re


def parse_csv_files():
    data = []
    
    # 81 Cities of Turkey for detection
    TR_CITIES = [
        "Adana", "Adıyaman", "Afyon", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın", "Balıkesir",
        "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli",
        "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane",
        "Hakkari", "Hatay", "Isparta", "Mersin", "İstanbul", "İzmir", "Kars", "Kastamonu", "Kayseri", "Kırklareli",
        "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa", "Kahramanmaraş", "Mardin", "Muğla", "Muş",
        "Nevşehir", "Niğde", "Ordu", "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat",
        "Trabzon", "Tunceli", "Şanlıurfa", "Uşak", "Van", "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman",
        "Kırıkkale", "Batman", "Şırnak", "Bartın", "Ardahan", "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
    ]
    
    # Mapping for universities/hospitals that don't satisfy the city check
    # Note: Many are covered by city check (e.g. Ankara Üni), but special ones need help.
    SPECIAL_MAP = {
        "Hacettepe": "Ankara",
        "Gazi Üniversitesi": "Ankara",
        "Boğaziçi": "İstanbul",
        "Ege Üniversitesi": "İzmir",
        "Dokuz Eylül": "İzmir",
        "Katip Çelebi": "İzmir",
        "Bakırçay": "İzmir",
        "Demokrasi": "İzmir",
        "Yüksek İhtisas": "Ankara", 
        "Dışkapı": "Ankara",
        "Etlik": "Ankara",
        "Sami Ulus": "Ankara",
        "Ulucanlar": "Ankara",
        "Dr. Abdurrahman Yurtaslan": "Ankara",
        "Gülhane": "Ankara",
        "Haydarpaşa": "İstanbul",
        "Cerrahpaşa": "İstanbul",
        "Çapa": "İstanbul",
        "Bezmiâlem": "İstanbul",
        "Medipol": "İstanbul",
        "Yeditepe": "İstanbul",
        "Acıbadem": "İstanbul",
        "Koç Üniversitesi": "İstanbul",
        "Sabancı": "İstanbul",
        "Biruni": "İstanbul",
        "Haliç": "İstanbul",
        "Altınbaş": "İstanbul",
        "Aydın Üniversitesi": "İstanbul",
        "Beykent": "İstanbul",
        "Gelişim": "İstanbul",
        "İstinye": "İstanbul",
        "Nişantaşı": "İstanbul",
        "Okan": "İstanbul",
        "Özyeğin": "İstanbul",
        "Piri Reis": "İstanbul",
        "Üsküdar": "İstanbul",
        "Yeni Yüzyıl": "İstanbul",
        "Demiroğlu Bilim": "İstanbul",
        "Atlas": "İstanbul",
        "Fenerbahçe": "İstanbul",
        "Galatasaray": "İstanbul",
        "Kent": "İstanbul",
        "Maltepe": "İstanbul",
        "Rumeli": "İstanbul",
        "Topkapı": "İstanbul",
        "Çukurova": "Adana",
        "Başkent": "Ankara",
        "Necmettin Erbakan": "Konya",
        "Karatay": "Konya",
        "Selçuk": "Konya",
        "Meram": "Konya",
        "Osmangazi": "Eskişehir",
        "Anadolu Üniversitesi": "Eskişehir",
        "Uludağ": "Bursa",
        "Yüksek İhtisas": "Bursa",
        "Celal Bayar": "Manisa",
        "Pamukkale": "Denizli",
        "Adnan Menderes": "Aydın",
        "Kocatepe": "Afyon",
        "Süleyman Demirel": "Isparta",
        "Dumlupınar": "Kütahya",
        "Bülent Ecevit": "Zonguldak",
        "Abant İzzet Baysal": "Bolu",
        "Karadeniz Teknik": "Trabzon",
        "Ahi Evran": "Trabzon", # Trabzon also has Ahi Evran hospital
        "Atatürk Üniversitesi": "Erzurum",
        "Fırat": "Elazığ",
        "İnönü": "Malatya",
        "Harran": "Şanlıurfa",
        "Dicle": "Diyarbakır",
        "Yüzüncü Yıl": "Van",
        "Sütçü İmam": "Kahramanmaraş",
        "Mustafa Kemal": "Hatay",
        "Tayfur Ata Sökmen": "Hatay",
        "Cumhuriyet": "Sivas",
        "Gaziosmanpaşa": "Tokat", # GOP Univ is Tokat. GOP Hospital is Istanbul. Tricky. Usually 'Tokat' is in univ name.
        "Bozok": "Yozgat",
        "Hitit": "Çorum",
        "Ahi Evran Üniversitesi": "Kırşehir",
        "Ömer Halisdemir": "Niğde",
        "Namık Kemal": "Tekirdağ",
        "Trakya": "Edirne",
        "Onsekiz Mart": "Çanakkale",
        "Muğla Sıtkı Koçman": "Muğla",
        "Recep Tayyip Erdoğan": "Rize",
        "Sakarya Üniversitesi": "Sakarya",
        "Düzce Üniversitesi": "Düzce",
        "Göztepe": "İstanbul",
        "Şişli": "İstanbul",
        "Okmeydanı": "İstanbul",
        "Kartal": "İstanbul",
        "Ümraniye": "İstanbul",
        "Samatya": "İstanbul",
        "Bakırköy": "İstanbul",
        "Kanuni Sultan Süleyman": "İstanbul",
        "Başakşehir": "İstanbul",
        "Çam ve Sakura": "İstanbul",
        "Siyami Ersek": "İstanbul",
        "Dr. Lütfi Kırdar": "İstanbul",
        "Süreyyapaşa": "İstanbul",
        "Fatih Sultan Mehmet": "İstanbul",
        "Haseki": "İstanbul",
        "Taksim": "İstanbul",
        "Gaziosmanpaşa Eğitim": "İstanbul", 
        "Bağcılar": "İstanbul",
        "Esenyurt": "İstanbul",
        "Kanuni": "İstanbul",
        "Zeynep Kamil": "İstanbul",
        "Erenköy": "İstanbul",
        "Sanatoryum": "Ankara",
        "Tepecik": "İzmir",
        "Bozyaka": "İzmir",
        "Dr. Behçet Uz": "İzmir",
        "Dr. Suat Seren": "İzmir", 
        "Şevket Yılmaz": "Bursa",
        "Dörtçelik": "Bursa",
        "Derince": "Kocaeli",
        "Darıca": "Kocaeli",
        "Gebze": "Kocaeli",
        "Ümraniye": "İstanbul",
        "Mehmet Akif İnan": "Şanlıurfa",
        "Eyyübiye": "Şanlıurfa",
        "Selahaddin Eyyubi": "Diyarbakır",
        "Gazi Yaşargil": "Diyarbakır",
        "Bölge Eğitim": "Erzurum", # Erzurum BEAH
        "Mengücek Gazi": "Erzincan",
        "Kaçkar": "Rize",
        "Akyazı": "Sakarya",
        "Korucuk": "Sakarya",
    }

    # Find the target directory (handling potential unicode/naming variations)
    base_dir = "/Users/gorkem/Downloads"
    target_dir = None
    
    for name in os.listdir(base_dir):
        if os.path.isdir(os.path.join(base_dir, name)) and "Yeni Klas" in name and "2" in name:
            target_dir = os.path.join(base_dir, name)
            break
            
    if not target_dir:
        files = glob.glob(os.path.join(base_dir, "TUS Sıralamalar - *.csv"))
    else:
        print(f"Found target directory: {target_dir}")
        files = glob.glob(os.path.join(target_dir, "*.csv"))
        if not files:
             files = glob.glob(os.path.join(target_dir, "TUS Sıralamalar - *.csv"))
    
    print(f"Found {len(files)} CSV files.")

    for filepath in files:
        # print(f"Processing {filepath}...")
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            from io import StringIO
            reader = csv.DictReader(StringIO(content))
            
            for row in reader:
                try:
                    institution_raw = row.get('Kurum', '').strip()
                    department = row.get('Bölüm', '').strip()
                    type_ = row.get('Tür', '').strip()
                    
                    # Split multi-line fields
                    # Ensure all lists have same length or handle mismatch
                    years_raw = row.get('Yıl', '').split('\n')
                    quotas_raw = row.get('Kont.', '').split('\n')
                    scores_raw = row.get('Puan', '').split('\n')
                    
                    # Determining the city
                    city = "Bilinmiyor"
                    
                    # 1. Check direct city match
                    for c in TR_CITIES:
                        # Case insensitive check might be safer but headers are capitalized
                        if c in institution_raw:
                            city = c
                            break
                    
                    # 2. Check special map if still unknown
                    if city == "Bilinmiyor":
                        for key, val in SPECIAL_MAP.items():
                            if key in institution_raw:
                                city = val
                                break

                    # Iterate over historical entries
                    # We iterate based on 'Year' entries.
                    for i, year_str in enumerate(years_raw):
                        year_clean = year_str.strip()
                        if not year_clean or year_clean == "-":
                            continue
                            
                        # Try to get corresponding quota and score
                        # Handle index out of bounds safely
                        quota_str = quotas_raw[i].strip() if i < len(quotas_raw) else "-"
                        score_str = scores_raw[i].strip() if i < len(scores_raw) else "-"
                        
                        # Parse Quota
                        quota = 0
                        if '/' in quota_str:
                            try: quota = int(quota_str.split('/')[0])
                            except: pass
                        elif quota_str.isdigit():
                            quota = int(quota_str)
                            
                        # Parse Score
                        min_score = 0.0
                        if score_str and score_str != "-":
                            clean_s = score_str.replace(',', '.')
                            try: min_score = float(clean_s)
                            except: min_score = 0.0
                        
                        # Skip if score is 0.0 AND it's not the most recent year?
                        # Or maybe user wants to see "Açıklanmadı"?
                        # Let's include everything that has a valid Year.
                        
                        record = {
                            "id": str(os.urandom(8).hex()),
                            "institution": institution_raw,
                            "department": department,
                            "city": city,
                            "type": type_,
                            "quota": quota,
                            "minScore": min_score,
                            "period": year_clean # Storing "2024/2"
                        }
                        data.append(record)
                    
                except Exception as e:
                    # print(f"Error parsing row: {e}")
                    continue
                    
        except Exception as e:
            print(f"Error reading file {filepath}: {e}")

    print(f"Total records parsed: {len(data)}")
    
    # Save to JSON
    output_path = "/Users/gorkem/WinTus/WinTUS/Resources/residency_data.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved to {output_path}")

if __name__ == "__main__":
    parse_csv_files()
