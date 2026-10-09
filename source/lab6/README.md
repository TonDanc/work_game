# Lab 6 : สร้างตัวละคร 3D

673380361-2 แดนชล ประไชโย

## โครงสร้าง

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `blender/` | `build_character.py` (สคริปต์ Blender สร้างโมเดล + rig), `make_face.py` (วาดใบหน้า), `face.png`, `student.blend`, `student.glb` |
| `game6/` | Godot project: Scene Demo แสดงท่าทาง (เว็บ: `docs/game6.html`) |
| `game6_play/` | เกม Lab 5 ที่เปลี่ยน Player เป็นตัวละครนี้ (เว็บ: `docs/game6_play.html`) |

## ขั้นตอนที่ทำ

1. **สร้างโมเดลใน Blender 4.5**: ตัวละครนักศึกษาสไตล์ low-poly (เสื้อขาว กางเกงดำ ป้ายชื่อ) หัวใช้ UV แบบทรงกลมเพื่อแปะภาพใบหน้า `face.png`
2. **Rig แบบ Mixamo**: โครงกระดูกท่า T-pose ใช้ชื่อกระดูกแบบ Mixamo (`mixamorig:Hips`, `mixamorig:Spine` ...) และมี animation `TPose` 1 ท่า
3. **Import เข้า Godot 4.7**: ตั้ง Skeleton ให้ใช้ `BoneMaps/Mixamo BoneMap.tres` (Godot จะ retarget เป็น `GeneralSkeleton`)
4. **ใส่ Animation Library**: `Libraries/MeleeLib.res` และ `Libraries/ShooterLib.res` จาก [Godot4-OpenAnimationLibraries](https://github.com/catprisbrey/Godot4-OpenAnimationLibraries)
5. **นำไปใช้**: Scene Demo (กดปุ่มเลือกท่า หมุน/ซูมกล้องได้) และเป็น Player ในเกม Lab 5

## เปลี่ยนใบหน้าเป็นรูปตัวเอง

1. เตรียมรูปขนาด 1024x512 ให้ใบหน้าอยู่กลางภาพ กินพื้นที่ประมาณ 1/3 ของความกว้าง แล้วบันทึกทับ `blender/face.png`
2. รัน `blender --background --python blender/build_character.py`
3. ก๊อป `blender/student.glb` ไปทับใน `game6/Character/` และ `game6_play/Character/`
4. Export Web ใหม่จาก Godot
