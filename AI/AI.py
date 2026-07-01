"""
AI recommendation service for SmartTour.

هذا الملف مكتوب بلغة Python ليقوم بحساب التوصيات الذكية للمستخدمين
بناءً على بيانات الأماكن في Firebase Firestore + تفضيلات المستخدم
(مثل الأماكن المفضّلة) + المسافة من موقعه الحالي.

الفكرة الأساسية:
  1) قراءة جميع الأماكن من مجموعة  places
  2) قراءة المفضلات من  user_favorites/{userId}/places
  3) حساب درجة (score) لكل مكان حسب:
       - القرب من المستخدم
       - التقييم وعدد المراجعات
       - تفضيلات المستخدم (الفئات التي يفضّلها)
  4) حفظ أفضل النتائج في  recommendations/{userId}  ليقرأها تطبيق Flutter

الاعتمادات المطلوبة (requirements):
  google-cloud-firestore

التشغيل محلياً (بعد إعداد حساب خدمة Service Account):
  1) ثبّت الحزم:
       pip install google-cloud-firestore
  2) اضبط متغيّر البيئة:
       export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
  3) نفّذ:
       python AI.py USER_ID 24.7136 46.6753
"""

from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from google.cloud import firestore


# ============================
# نماذج بيانات مساعدة
# ============================


@dataclass
class UserLocation:
  latitude: float
  longitude: float


@dataclass
class PlaceDoc:
  id: str
  name: str
  name_en: str
  description: str
  description_en: str
  category: str
  category_en: str
  rating: float
  reviews: int
  latitude: float
  longitude: float
  image_url: Optional[str]

  @staticmethod
  def from_firestore(doc: firestore.DocumentSnapshot) -> "PlaceDoc":
    data = doc.to_dict() or {}

    def _get_str(key: str, default: str = "") -> str:
      value = data.get(key, default)
      return str(value) if value is not None else default

    def _get_float(key: str, default: float = 0.0) -> float:
      value = data.get(key)
      if value is None:
        return default
      if isinstance(value, (int, float)):
        return float(value)
      try:
        return float(value)
      except Exception:
        return default

    def _get_int(key: str, default: int = 0) -> int:
      value = data.get(key)
      if value is None:
        return default
      if isinstance(value, (int, float)):
        return int(value)
      try:
        return int(value)
      except Exception:
        return default

    return PlaceDoc(
      id=doc.id,
      name=_get_str("name", ""),
      name_en=_get_str("nameEn", _get_str("name", "")),
      description=_get_str("description", ""),
      description_en=_get_str("descriptionEn", _get_str("description", "")),
      category=_get_str("category", ""),
      category_en=_get_str("categoryEn", _get_str("category", "")),
      rating=_get_float("rating", 0.0),
      reviews=_get_int("reviews", 0),
      latitude=_get_float("latitude", 0.0),
      longitude=_get_float("longitude", 0.0),
      image_url=data.get("imageUrl"),
    )


# ============================
# دوال مسافة (هفرسين)
# ============================


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
  """احسب المسافة بين نقطتين (كم) باستخدام صيغة هفرسين."""
  # نصف قطر الأرض بالكيلومتر
  R = 6371.0

  # التحويل إلى راديان
  phi1 = math.radians(lat1)
  phi2 = math.radians(lat2)
  dphi = math.radians(lat2 - lat1)
  dlambda = math.radians(lon2 - lon1)

  a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
  c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

  return R * c


# ============================
# دوال Firestore
# ============================


def get_firestore_client() -> firestore.Client:
  """تهيئة عميل Firestore. يعتمد على GOOGLE_APPLICATION_CREDENTIALS."""
  return firestore.Client()


def fetch_places(db: firestore.Client, limit: int = 500) -> List[PlaceDoc]:
  """جلب جميع الأماكن من مجموعة places."""
  docs = db.collection("places").limit(limit).stream()
  places: List[PlaceDoc] = []
  for d in docs:
    try:
      places.append(PlaceDoc.from_firestore(d))
    except Exception as e:
      print(f"[AI] Error parsing place {d.id}: {e}", file=sys.stderr)
  print(f"[AI] Loaded {len(places)} places from Firestore.")
  return places


def fetch_user_favorite_categories(db: firestore.Client, user_id: str) -> List[str]:
  """
  جلب الفئات المفضلة للمستخدم من:
    user_favorites/{userId}/places
  """
  fav_ref = (
    db.collection("user_favorites")
    .document(user_id)
    .collection("places")
  )
  docs = fav_ref.stream()
  categories: List[str] = []
  for d in docs:
    data = d.to_dict() or {}
    cat = data.get("category")
    cat_en = data.get("categoryEn")
    if cat:
      categories.append(str(cat))
    if cat_en:
      categories.append(str(cat_en))

  print(f"[AI] Loaded {len(categories)} favorite category entries for user {user_id}.")
  return categories


# ============================
# خوارزمية التوصية
# ============================


def build_category_preferences(categories: List[str]) -> Dict[str, float]:
  """
  بناء خريطة تفضيل للفئات (Category -> score) من المفضلات.
  """
  prefs: Dict[str, int] = {}
  for c in categories:
    key = c.strip().lower()
    if not key:
      continue
    prefs[key] = prefs.get(key, 0) + 1

  if not prefs:
    return {}

  max_count = max(prefs.values())
  norm_prefs: Dict[str, float] = {}
  for k, v in prefs.items():
    norm_prefs[k] = v / max_count

  print(f"[AI] Built {len(norm_prefs)} normalized category preferences.")
  return norm_prefs


def score_place(
  place: PlaceDoc,
  user_location: Optional[UserLocation],
  cat_prefs: Dict[str, float],
  alpha: float = 0.45,
  beta: float = 0.35,
  gamma: float = 0.20,
) -> Tuple[float, float]:
  """
  حساب درجة المكان.

  alpha: وزن القرب
  beta : وزن جودة/شعبية المكان
  gamma: وزن تفضيلات المستخدم
  """
  # ---- القرب ----
  if user_location and (place.latitude != 0.0 or place.longitude != 0.0):
    dist_km = haversine_km(
      user_location.latitude,
      user_location.longitude,
      place.latitude,
      place.longitude,
    )
  else:
    # إذا لا يوجد موقع للمستخدم أو إحداثيات للمكان، نعتبره بعيد
    dist_km = 9999.0

  distance_score = 1.0 / (1.0 + dist_km)  # كلما اقترب المكان زادت الدرجة

  # ---- جودة/شعبية المكان ----
  rating = max(0.0, min(place.rating, 5.0))
  rating_norm = rating / 5.0
  reviews_log = math.log1p(max(place.reviews, 0))  # log(1 + reviews)
  popularity = min(reviews_log / 10.0, 1.0)  # تطبيع بسيط من 0 إلى ~1
  quality_score = 0.7 * rating_norm + 0.3 * popularity

  # ---- تفضيلات المستخدم ----
  cat_keys = {
    place.category.strip().lower(),
    place.category_en.strip().lower(),
  }
  pref_values = [cat_prefs.get(k, 0.0) for k in cat_keys if k]
  if pref_values:
    pref_score = max(pref_values)
  else:
    pref_score = 0.5  # قيمة افتراضية متوسطة

  # ---- الجمع الكلي ----
  total_score = alpha * distance_score + beta * quality_score + gamma * pref_score
  return float(total_score), float(dist_km)


def generate_recommendations(
  user_id: str,
  user_location: Optional[UserLocation] = None,
  top_k: int = 20,
) -> List[Dict]:
  """
  توليد قائمة توصيات لمستخدم معيّن وكتابتها في:
    recommendations/{userId}

  تعيد قائمة من القواميس (dict) للأماكن الموصى بها.
  """
  db = get_firestore_client()

  # 1) جلب البيانات
  places = fetch_places(db)
  fav_categories = fetch_user_favorite_categories(db, user_id)
  cat_prefs = build_category_preferences(fav_categories)

  # 2) حساب الدرجات
  scored: List[Tuple[PlaceDoc, float, float]] = []  # (place, score, dist_km)
  for p in places:
    score, dist_km = score_place(p, user_location, cat_prefs)
    scored.append((p, score, dist_km))

  # 3) ترتيب وأخذ أفضل N
  scored.sort(key=lambda x: x[1], reverse=True)
  top = scored[:top_k]

  results: List[Dict] = []
  for place, score, dist_km in top:
    results.append(
      {
        "placeId": place.id,
        "score": round(score, 4),
        "distanceKm": round(dist_km, 3),
        "name": place.name,
        "nameEn": place.name_en,
        "category": place.category,
        "categoryEn": place.category_en,
        "rating": place.rating,
        "reviews": place.reviews,
        "imageUrl": place.image_url,
      }
    )

  # 4) كتابة النتائج إلى Firestore في مسار recommendations/{userId}
  rec_ref = firestore.Client().collection("recommendations").document(user_id)
  rec_ref.set(
    {
      "items": results,
      "updatedAt": firestore.SERVER_TIMESTAMP,
    }
  )

  print(f"[AI] Wrote {len(results)} recommendations for user {user_id}.")
  return results


# ============================
# نقطة تشغيل بسيطة من سطر الأوامر
# ============================


def _parse_user_location_from_args(args: List[str]) -> Optional[UserLocation]:
  """
  قراءة إحداثيات المستخدم من argv:
    python AI.py USER_ID [lat lon]
  """
  if len(args) < 3:
    return None
  try:
    lat = float(args[1])
    lon = float(args[2])
    return UserLocation(latitude=lat, longitude=lon)
  except Exception:
    print("[AI] Invalid lat/lon, ignoring user location.", file=sys.stderr)
    return None


if __name__ == "__main__":
  if len(sys.argv) < 2:
    print("Usage: python AI.py USER_ID [LAT LON]")
    sys.exit(1)

  user_id = sys.argv[1]
  loc = _parse_user_location_from_args(sys.argv[1:])

  print(f"[AI] Generating recommendations for user: {user_id}")
  if loc:
    print(f"[AI] Using user location: lat={loc.latitude}, lon={loc.longitude}")
  else:
    print("[AI] No user location provided, recommendations will ignore distance.")

  recs = generate_recommendations(user_id, user_location=loc, top_k=20)
  print("[AI] Done. Top recommendations:")
  for r in recs:
    print(f"  - {r['name']} (score={r['score']}, distance={r['distanceKm']} km)")


