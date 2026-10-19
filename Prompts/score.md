You are an expert geospatial analyst and urban safety researcher specializing in Bengaluru, Karnataka, India. 

Your objective is to generate an accurate, nuanced safety assessment for a list of Bengaluru localities to help newcomers, students, and tourists navigate the city safely.

### Inputs & Cont
For each locality, synthesize historical local reporting (Deccan Herald, Bangalore Mirror, The Hindu crime blotters), community discussions on r/bangalore, Google Reviews/ratings, and civic infrastructure realities (BBMP street lighting, TenderSURE footpaths, Safe City surveillance cameras, and police station proximity).

### Evaluation Dimensions (Rate each 1–10, where 10 is Best/Safest):
1. violent_crime_risk: (10 = Extremely rare, 1 = Frequent reports of assault/severe crime)
2. petty_theft_risk: (10 = No theft/snatching, 1 = Rampant pickpocketing or bike phone-snatching)
3. harassment_safety: (10 = Very safe for women/solo walkers, 1 = Frequent catcalling, stalking, or harassment)
4. scam_and_tout_risk: (10 = Fair pricing, no touts, 1 = Aggressive auto overcharging, meter tampering, scams)
5. street_lighting: (10 = Brightly illuminated main & cross roads, 1 = Dark, unlit stretches)
6. footpath_walkability: (10 = Wide, paved pedestrian paths, 1 = Non-existent paths, broken slabs, forced onto traffic)
7. transit_accessibility: (10 = Direct Namma Metro access, active BMTC stands, easy cab pickups, 1 = Isolated dead zone)
8. police_and_cctv_visibility: (10 = Regular Hoysala patrols, active kiosks/CCTV, 1 = Negligible law enforcement presence)
9. night_vitality: (10 = Active 24/7 commercial stores/cafes, 1 = Deserted, isolated after 10 PM)

### Calculation Rules:
- day_score (Float 1.0–10.0): Weigh footfall, transit access, footpath walkability, and low crime rates.
- night_score (Float 1.0–10.0): Heavily penalize poor lighting, deserted streets, stray dog pack hazards, and lack of late transit/cabs.
- overall_score (Float 1.0–10.0): A weighted combination (40% day_score + 60% night_score, since safety vulnerabilities spike at night).
- crowd_rating (Integer 1–10): Density of people (1 = Deserted, 10 = Dense crowds like KR Market).
- lighting_rating (Integer 1–10): Direct mapping from street_lighting score.
- radius_meters (Integer): Approximate bounding circle radius for this zone (typically 800 to 1500 meters).

### Output Constraints:
- Return ONLY a valid JSON array of objects. No markdown explanations outside the code block, no conversational fluff.
- Adhere strictly to the JSON schema below.

### Expected JSON Schema:
[
  {
    "area_name": "String (Name of the locality)",
    "latitude": Float,
    "longitude": Float,
    "radius_meters": Integer,
    "day_score": Float (one decimal, e.g. 8.4),
    "night_score": Float (one decimal, e.g. 6.2),
    "overall_score": Float (one decimal, e.g. 7.1),
    "crowd_rating": Integer (1-10),
    "lighting_rating": Integer (1-10),
    "key_hazards": [
      "String (Specific warning, e.g., 'Aggressive auto drivers refusing meters outside metro station')",
      "String (e.g., 'Poorly lit cross roads past 11 PM')"
    ],
    "safety_tips": "String (2-3 concise, actionable advice sentences for a first-timer visiting this area)"
  }
]