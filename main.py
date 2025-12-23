import sys
import os
import platform
import subprocess
from pathlib import Path
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Property, Slot, QUrl
from peewee import *

db = SqliteDatabase('gallery.db')

class BaseModel(Model):
    class Meta:
        database = db

class Category(BaseModel):
    name = CharField(unique=True)
    description = TextField(null=True)
    color = CharField(default="#3498db")

class Photo(BaseModel):
    path = CharField(unique=True)
    description = TextField(null=True)
    category = ForeignKeyField(Category, backref='photos', null=True, on_delete='SET NULL')

def create_tables():
    db.connect()
    db.create_tables([Category, Photo], safe=True)
    db.close()

class Backend(QObject):
    categoriesChanged = Signal()
    photosChanged = Signal()
    
    def __init__(self):
        super().__init__()
        create_tables()
        self._current_category = 0
        self._photos = []
        self._categories = []
        self.create_basic_categories()
        self.update_categories()
        self.update_photos(0)
    
    def create_basic_categories(self):
        try:
            if not Category.select().where(Category.name == "Все фото").exists():
                Category.create(
                    name="Все фото",
                    description="Все фотографии в галерее",
                    color="#95a5a6"
                )
        except Exception as e:
            print(f"Ошибка при создании категорий: {e}")
    
    @Property(list, notify=categoriesChanged)
    def categories(self):
        return self._categories
    
    @Property(list, notify=photosChanged)
    def photos(self):
        return self._photos
    
    @Slot()
    def update_categories(self):
        try:
            self._categories = [
                {
                    "id": 0,
                    "name": "Все фото",
                    "description": "Все фотографии",
                    "color": "#95a5a6"
                }
            ]
            
            for c in Category.select().where(Category.id > 1).order_by(Category.name):
                self._categories.append({
                    "id": c.id,
                    "name": c.name,
                    "description": c.description or "",
                    "color": c.color
                })
            
            self.categoriesChanged.emit()
            return True
        except Exception as e:
            print(f"Ошибка при обновлении категорий: {e}")
            return False
    
    @Slot(int)
    def update_photos(self, category_id=0):
        try:
            query = Photo.select()
            
            if category_id > 0:
                query = query.where(Photo.category == category_id)
            
            self._photos = []
            for p in query:
                file_exists = os.path.exists(p.path)
                
                category_info = {}
                if p.category:
                    category_info = {
                        "id": p.category.id,
                        "name": p.category.name,
                        "description": p.category.description or "",
                        "color": p.category.color
                    }
                
                qml_path = QUrl.fromLocalFile(os.path.abspath(p.path)).toString() if file_exists else ""
                
                self._photos.append({
                    "id": p.id,
                    "path": p.path,
                    "qml_path": qml_path,
                    "description": p.description or "",
                    "category": category_info,
                    "filename": os.path.basename(p.path),
                    "file_exists": file_exists
                })
            
            self.photosChanged.emit()
            return True
        except Exception as e:
            print(f"Ошибка при обновлении фотографий: {e}")
            return False
    
    @Slot(str, str, str)
    def add_category(self, name, description, color):
        try:
            if not name.strip():
                return False
                
            Category.create(
                name=name.strip(),
                description=description.strip(),
                color=color
            )
            self.update_categories()
            return True
        except Exception as e:
            print(f"Ошибка при добавлении категории: {e}")
            return False
    
    @Slot(int, str, str, str, result=bool)
    def update_category(self, category_id, name, description, color):
        try:
            if not name.strip():
                return False
                
            category = Category.get_by_id(category_id)
            category.name = name.strip()
            category.description = description.strip()
            category.color = color
            category.save()
            
            self.update_categories()
            self.update_photos(self._current_category)
            return True
        except Exception as e:
            print(f"Ошибка при обновлении категории: {e}")
            return False
    
    @Slot(int)
    def delete_category(self, category_id):
        try:
            category = Category.get_by_id(category_id)
            category_name = category.name
            
            Photo.update(category=None).where(Photo.category == category_id).execute()
            
            category.delete_instance()
            
            self.update_categories()
            
            if self._current_category == category_id:
                self.update_photos(0)
                self._current_category = 0
            else:
                self.update_photos(self._current_category)
            
            print(f"Удалена категория: {category_name}")
            return True
        except Exception as e:
            print(f"Ошибка при удалении категории: {e}")
            return False
    
    @Slot(str, str, int, result=bool)
    def add_photo(self, path, description, category_id):
        try:
            if not path.strip():
                return False
            
            if path.startswith("file:///"):
                path = QUrl(path).toLocalFile()
            
            if Photo.select().where(Photo.path == path).exists():
                return False
                
            category = None
            if category_id > 0:
                try:
                    category = Category.get_by_id(category_id)
                except:
                    pass
            
            Photo.create(
                path=path.strip(),
                description=description.strip(),
                category=category
            )
            
            self.update_categories()
            self.update_photos(self._current_category)
            return True
        except Exception as e:
            print(f"Ошибка при добавлении фото: {e}")
            return False
    
    @Slot(int, int, result=bool)
    def set_photo_category(self, photo_id, category_id):
        try:
            photo = Photo.get_by_id(photo_id)
            
            category = None
            if category_id > 0:
                try:
                    category = Category.get_by_id(category_id)
                except:
                    pass
            
            photo.category = category
            photo.save()
            
            self.update_categories()
            self.update_photos(self._current_category)
            return True
        except Exception as e:
            print(f"Ошибка при изменении категории фото: {e}")
            return False
    
    @Slot(int, result=bool)
    def delete_photo(self, photo_id):
        try:
            photo = Photo.get_by_id(photo_id)
            photo_name = os.path.basename(photo.path)
            
            try:
                if os.path.exists(photo.path):
                    os.remove(photo.path)
                    print(f"Удален файл: {photo_name}")
            except Exception as file_error:
                print(f"Не удалось удалить файл {photo_name}: {file_error}")
            
            photo.delete_instance()
            
            print(f"Удалено фото из базы: {photo_name}")
            
            self.update_categories()
            self.update_photos(self._current_category)
            
            return True
        except Exception as e:
            print(f"Ошибка при удалении фото: {e}")
            return False
    
    @Slot(int, str, result=bool)
    def update_photo_description(self, photo_id, description):
        try:
            photo = Photo.get_by_id(photo_id)
            photo.description = description.strip()
            photo.save()
            
            self.update_photos(self._current_category)
            return True
        except Exception as e:
            print(f"Ошибка при обновлении описания фото: {e}")
            return False
    
    @Slot(int, str, result=bool)
    def rename_photo_file(self, photo_id, new_filename):
        try:
            photo = Photo.get_by_id(photo_id)
            
            old_path = photo.path
            old_dir = os.path.dirname(old_path)
            
            old_ext = os.path.splitext(old_path)[1]
            new_filename = new_filename.strip()
            
            if not os.path.splitext(new_filename)[1]:
                new_filename += old_ext
            
            new_path = os.path.join(old_dir, new_filename)
            
            if os.path.exists(new_path) and new_path != old_path:
                print(f"Файл с именем {new_filename} уже существует")
                return False
            
            try:
                if old_path != new_path:
                    os.rename(old_path, new_path)
                    print(f"Файл переименован: {os.path.basename(old_path)} -> {new_filename}")
            except Exception as file_error:
                print(f"Не удалось переименовать файл: {file_error}")
                return False
            
            photo.path = new_path
            photo.save()
            
            self.update_categories()
            self.update_photos(self._current_category)
            
            return True
        except Exception as e:
            print(f"Ошибка при переименовании файла: {e}")
            return False
    
    @Slot(int)
    def set_current_category(self, category_id):
        self._current_category = category_id
        self.update_photos(category_id)
    
    @Slot(str, result=bool)
    def show_in_explorer(self, file_path):
        try:
            file_path = os.path.normpath(file_path)
            
            if platform.system() == "Windows":
                if os.path.exists(file_path):
                    subprocess.Popen(f'explorer /select,"{file_path}"')
                else:
                    parent_dir = os.path.dirname(file_path)
                    if os.path.exists(parent_dir):
                        subprocess.Popen(f'explorer "{parent_dir}"')
            elif platform.system() == "Darwin":
                if os.path.exists(file_path):
                    subprocess.Popen(["open", "-R", file_path])
                else:
                    parent_dir = os.path.dirname(file_path)
                    if os.path.exists(parent_dir):
                        subprocess.Popen(["open", parent_dir])
            else:
                if os.path.exists(file_path):
                    subprocess.Popen(["xdg-open", os.path.dirname(file_path)])
                else:
                    parent_dir = os.path.dirname(file_path)
                    if os.path.exists(parent_dir):
                        subprocess.Popen(["xdg-open", parent_dir])
            return True
        except Exception as e:
            print(f"Ошибка при открытии в проводнике: {e}")
            return False

if __name__ == "__main__":
    print("Запуск приложения...")
    
    app = QApplication(sys.argv)
    backend = Backend()
    
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    
    qml_file = Path(__file__).parent / "frontend.qml"
    
    if not qml_file.exists():
        print(f"Файл {qml_file} не найден!") 
        sys.exit(-1)
    
    engine.load(str(qml_file))
    
    if not engine.rootObjects():
        print("Не удалось загрузить QML интерфейс")
        sys.exit(-1)
    
    print("Приложение успешно запущено!")
    sys.exit(app.exec())
