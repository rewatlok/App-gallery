import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1200
    height: 700
    title: "Галерея фотографий"
    visible: true

    FileDialog {
        id: fileDialog
        title: "Выберите фотографии"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Изображения (*.jpg *.jpeg *.png *.bmp *.gif)"]
        onAccepted: {
            for (var i = 0; i < selectedFiles.length; i++) {
                backend.add_photo(selectedFiles[i], "", categoryCombo.currentValue)
            }
        }
    }

    Popup {
        id: deletePhotoPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 200
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ddd"
            border.width: 1
        }
        
        property var photoIds: []
        property int photoCount: 0
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Text {
                text: "Удаление фотографий"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: deletePhotoPopup.photoCount === 1 ? 
                      "Вы уверены, что хотите удалить выбранное фото?" :
                      "Вы уверены, что хотите удалить " + deletePhotoPopup.photoCount + " выбранных фотографий?"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    onClicked: deletePhotoPopup.close()
                }
                
                Button {
                    text: "Удалить"
                    Layout.fillWidth: true
                    onClicked: {
                        for (var i = 0; i < deletePhotoPopup.photoIds.length; i++) {
                            backend.delete_photo(deletePhotoPopup.photoIds[i])
                        }
                        selectedPhotoIds.clear()
                        deletePhotoPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: categorySelectPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 300
        height: 400
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ddd"
            border.width: 1
        }
        
        property var photoIds: []
        property int photoCount: 0
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            
            Text {
                text: categorySelectPopup.photoCount === 1 ? 
                      "Выберите категорию для фото" :
                      "Выберите категорию для " + categorySelectPopup.photoCount + " фото"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Button {
                        width: parent.width
                        height: 40
                        text: "🗑️ Без категории"
                        onClicked: {
                            for (var i = 0; i < categorySelectPopup.photoIds.length; i++) {
                                backend.set_photo_category(categorySelectPopup.photoIds[i], 0)
                            }
                            selectedPhotoIds.clear()
                            categorySelectPopup.close()
                        }
                        
                        background: Rectangle {
                            color: "#ecf0f1"
                            radius: 3
                            border.width: 1
                            border.color: "#ddd"
                        }
                    }
                    
                    Repeater {
                        model: backend ? backend.categories.filter(c => c.id !== 0) : []
                        
                        delegate: Button {
                            width: parent.width
                            height: 40
                            text: "● " + modelData.name
                            
                            onClicked: {
                                for (var i = 0; i < categorySelectPopup.photoIds.length; i++) {
                                    backend.set_photo_category(categorySelectPopup.photoIds[i], modelData.id)
                                }
                                selectedPhotoIds.clear()
                                categorySelectPopup.close()
                            }
                            
                            background: Rectangle {
                                color: "#ecf0f1"
                                radius: 3
                                border.width: 1
                                border.color: "#ddd"
                            }
                            
                            contentItem: RowLayout {
                                spacing: 10
                                
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: modelData.color
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                
                                Text {
                                    text: parent.parent.text
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
            
            Button {
                text: "Отмена"
                Layout.fillWidth: true
                onClicked: categorySelectPopup.close()
            }
        }
    }

    Popup {
        id: photoViewPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 800
        height: 600
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ddd"
            border.width: 1
        }
        
        property var photoData: null
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Text {
                text: "Просмотр фотографии"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#f8f9fa"
                radius: 3
                
                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    source: photoViewPopup.photoData ? photoViewPopup.photoData.qml_path : ""
                    fillMode: Image.PreserveAspectFit
                    
                    Rectangle {
                        visible: !parent.source || parent.status === Image.Error
                        anchors.fill: parent
                        color: "#ecf0f1"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Изображение не загружено"
                            color: "#95a5a6"
                            font.pixelSize: 14
                        }
                    }
                }
            }
            
            GroupBox {
                title: "Информация о файле"
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 5
                    
                    Text {
                        text: "Исходный путь:"
                        font.pixelSize: 12
                        color: "#7f8c8d"
                    }
                    
                    TextField {
                        id: originalPathField
                        Layout.fillWidth: true
                        text: photoViewPopup.photoData ? photoViewPopup.photoData.path : ""
                        readOnly: true
                        selectByMouse: true
                        font.pixelSize: 11
                    }
                    
                    Text {
                        text: "Имя файла:"
                        font.pixelSize: 12
                        color: "#7f8c8d"
                    }
                    
                    TextField {
                        id: fileNameField
                        Layout.fillWidth: true
                        text: photoViewPopup.photoData ? photoViewPopup.photoData.filename : ""
                        placeholderText: "Введите новое имя файла"
                        font.pixelSize: 11
                        
                        Button {
                            id: renameButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            height: 20
                            text: "✎"
                            visible: fileNameField.text !== (photoViewPopup.photoData ? photoViewPopup.photoData.filename : "")
                            font.pixelSize: 10
                            
                            onClicked: {
                                if (photoViewPopup.photoData && fileNameField.text.trim()) {
                                    backend.rename_photo_file(photoViewPopup.photoData.id, fileNameField.text)
                                    photoViewPopup.close()
                                }
                            }
                            
                            background: Rectangle {
                                color: parent.down ? "#3498db" : parent.hovered ? "#2980b9" : "#3498db"
                                radius: 3
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font: parent.font
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    
                    Text {
                        text: "Текущая категория:"
                        font.pixelSize: 12
                        color: "#7f8c8d"
                    }
                    
                    Text {
                        text: photoViewPopup.photoData && photoViewPopup.photoData.category ? 
                              photoViewPopup.photoData.category.name : "Без категории"
                        font.pixelSize: 11
                        color: photoViewPopup.photoData && photoViewPopup.photoData.category ? 
                               photoViewPopup.photoData.category.color : "#95a5a6"
                    }
                }
            }
            
            GroupBox {
                title: "Описание фотографии"
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    
                    TextArea {
                        id: photoDescriptionField
                        anchors.fill: parent
                        text: photoViewPopup.photoData ? photoViewPopup.photoData.description : ""
                        wrapMode: TextArea.Wrap
                        placeholderText: "Введите описание фотографии (необязательно)..."
                        font.pixelSize: 12
                        
                        background: Rectangle {
                            color: "#f8f9fa"
                            border.color: "#ddd"
                            border.width: 1
                            radius: 3
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    onClicked: photoViewPopup.close()
                }
                
                Button {
                    text: "Сохранить описание"
                    Layout.fillWidth: true
                    onClicked: {
                        if (photoViewPopup.photoData) {
                            backend.update_photo_description(photoViewPopup.photoData.id, photoDescriptionField.text)
                            photoViewPopup.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: editCategoryPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 500
        height: 300
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ddd"
            border.width: 1
        }
        
        property var categoryData: null
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Text {
                text: "Редактировать категорию"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true
                
                Text { 
                    text: "Название:" 
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 12
                }
                
                TextField {
                    id: editCategoryName
                    Layout.fillWidth: true
                    placeholderText: "Введите название"
                    font.pixelSize: 12
                }
                
                Text { 
                    text: "Описание:" 
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 12
                }
                
                TextField {
                    id: editCategoryDescription
                    Layout.fillWidth: true
                    placeholderText: "Введите описание (необязательно)"
                    font.pixelSize: 12
                }
                
                Text { 
                    text: "Цвет:" 
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 12
                }
                
                ComboBox {
                    id: editColorCombo
                    model: [
                        { name: "Синий", value: "#3498db" },
                        { name: "Зеленый", value: "#2ecc71" },
                        { name: "Красный", value: "#e74c3c" },
                        { name: "Оранжевый", value: "#f39c12" },
                        { name: "Фиолетовый", value: "#9b59b6" },
                        { name: "Серый", value: "#95a5a6" },
                        { name: "Бирюзовый", value: "#1abc9c" },
                        { name: "Темно-синий", value: "#34495e" },
                        { name: "Розовый", value: "#e84393" }
                    ]
                    textRole: "name"
                    valueRole: "value"
                    Layout.fillWidth: true
                    
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 30
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Rectangle {
                                width: 15
                                height: 15
                                radius: 7
                                color: model.value
                            }
                            
                            Text {
                                text: model.name
                                Layout.fillWidth: true
                                font.pixelSize: 12
                            }
                        }
                    }
                    
                    contentItem: RowLayout {
                        spacing: 10
                        
                        Rectangle {
                            width: 15
                            height: 15
                            radius: 7
                            color: editColorCombo.currentValue
                        }
                        
                        Text {
                            text: editColorCombo.currentText
                            Layout.fillWidth: true
                            font.pixelSize: 12
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    onClicked: editCategoryPopup.close()
                }
                
                Button {
                    text: "Сохранить"
                    Layout.fillWidth: true
                    onClicked: {
                        if (editCategoryName.text.trim() && editCategoryPopup.categoryData) {
                            backend.update_category(
                                editCategoryPopup.categoryData.id,
                                editCategoryName.text,
                                editCategoryDescription.text,
                                editColorCombo.currentValue
                            )
                            editCategoryPopup.close()
                        }
                    }
                }
            }
        }
        
        function openWithCategory(category) {
            editCategoryPopup.categoryData = category
            editCategoryName.text = category.name
            editCategoryDescription.text = category.description || ""
            
            var colorIndex = -1
            for (var i = 0; i < editColorCombo.model.length; i++) {
                if (editColorCombo.model[i].value === category.color) {
                    colorIndex = i
                    break
                }
            }
            if (colorIndex !== -1) {
                editColorCombo.currentIndex = colorIndex
            } else {
                editColorCombo.model.push({name: "Текущий", value: category.color})
                editColorCombo.currentIndex = editColorCombo.model.length - 1
            }
            
            editCategoryPopup.open()
        }
    }

    Menu {
        id: photoContextMenu
        width: 200
        property var photoIds: []
        property int photoCount: 0

MenuItem {
    id: fullScreenItem
    text: "Просмотр фото (полноэкранный)"
    height: 28
    visible: photoContextMenu.photoCount === 1
    
    contentItem: Text {
        text: fullScreenItem.text
        font.pixelSize: 11
        color: fullScreenItem.enabled ? "#333" : "#999"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: 10
        rightPadding: 10
        elide: Text.ElideRight
    }
    
    background: Rectangle {
        color: fullScreenItem.hovered ? "#f0f7ff" : "transparent"
    }
    
    onTriggered: {
        var photoId = photoContextMenu.photoIds[0]
        var photo = null
        
        for (var i = 0; i < backend.photos.length; i++) {
            if (backend.photos[i].id === photoId) {
                photo = backend.photos[i]
                break
            }
        }
        
        if (photo) {
            fullScreenPhotoPopup.photoData = photo
            fullScreenPhotoPopup.open()
        }
    }
}
        
        MenuItem {
            id: viewEditItem
            text: "Просмотреть и редактировать"
            height: 28
            visible: photoContextMenu.photoCount === 1
            
            contentItem: Text {
                text: viewEditItem.text
                font.pixelSize: 11
                color: viewEditItem.enabled ? "#333" : "#999"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                elide: Text.ElideRight
            }
            
            background: Rectangle {
                color: viewEditItem.hovered ? "#f0f7ff" : "transparent"
            }
            
            onTriggered: {
                var photoId = photoContextMenu.photoIds[0]
                var photo = null
                
                for (var i = 0; i < backend.photos.length; i++) {
                    if (backend.photos[i].id === photoId) {
                        photo = backend.photos[i]
                        break
                    }
                }
                
                if (photo) {
                    photoViewPopup.photoData = photo
                    photoViewPopup.open()
                }
            }
        }
        
        MenuItem {
            id: locateFileItem
            text: "Показать в проводнике"
            height: 28
            visible: photoContextMenu.photoCount === 1
            
            contentItem: Text {
                text: locateFileItem.text
                font.pixelSize: 11
                color: locateFileItem.enabled ? "#333" : "#999"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                elide: Text.ElideRight
            }
            
            background: Rectangle {
                color: locateFileItem.hovered ? "#f0f7ff" : "transparent"
            }
            
            onTriggered: {
                var photoId = photoContextMenu.photoIds[0]
                var photo = null
                
                for (var i = 0; i < backend.photos.length; i++) {
                    if (backend.photos[i].id === photoId) {
                        photo = backend.photos[i]
                        break
                    }
                }
                
                if (photo && photo.path) {
                    backend.show_in_explorer(photo.path)
                }
            }
        }
        
        MenuItem {
            id: assignCategoryItem
            text: photoContextMenu.photoCount === 1 ? "Назначить категорию" : "Назначить категорию (" + photoContextMenu.photoCount + ")"
            height: 28
            
            contentItem: Text {
                text: assignCategoryItem.text
                font.pixelSize: 11
                color: assignCategoryItem.enabled ? "#333" : "#999"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                elide: Text.ElideRight
            }
            
            background: Rectangle {
                color: assignCategoryItem.hovered ? "#f0f7ff" : "transparent"
            }
            
            onTriggered: {
                categorySelectPopup.photoIds = photoContextMenu.photoIds.slice()
                categorySelectPopup.photoCount = photoContextMenu.photoCount
                categorySelectPopup.open()
            }
        }
        
        MenuItem {
            id: deleteItem
            text: photoContextMenu.photoCount === 1 ? "Удалить фото" : "Удалить (" + photoContextMenu.photoCount + ")"
            height: 28
            
            contentItem: Text {
                text: deleteItem.text
                font.pixelSize: 11
                color: deleteItem.enabled ? "#d32f2f" : "#999"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                elide: Text.ElideRight
            }
            
            background: Rectangle {
                color: deleteItem.hovered ? "#ffebee" : "transparent"
            }
            
            onTriggered: {
                deletePhotoPopup.photoIds = photoContextMenu.photoIds.slice()
                deletePhotoPopup.photoCount = photoContextMenu.photoCount
                deletePhotoPopup.open()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#2c3e50"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15
                
                Text {
                    text: "Галерея фотографий"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "Фото: " + (backend ? backend.photos.length : 0) + 
                          (selectedPhotoIds.count > 0 ? " (Выбрано: " + selectedPhotoIds.count + ")" : "")
                    color: "white"
                    font.pixelSize: 14
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#ecf0f1"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 10
                
                ComboBox {
                    id: categoryCombo
                    Layout.preferredWidth: 200
                    model: backend ? backend.categories : []
                    textRole: "name"
                    valueRole: "id"
                    
                    onCurrentValueChanged: {
                        backend.set_current_category(currentValue)
                        selectedPhotoIds.clear()
                    }
                    
                    Component.onCompleted: {
                        currentIndex = 0
                    }
                }
                
                Button {
                    text: "Добавить фото"
                    onClicked: fileDialog.open()
                }
                
                Button {
                    text: "Управление категориями"
                    onClicked: categoryPopup.open()
                }
                
                Button {
                    text: "Выделить все"
                    onClicked: {
                        if (backend && backend.photos.length > 0) {
                            selectedPhotoIds.clear()
                            for (var i = 0; i < backend.photos.length; i++) {
                                selectedPhotoIds.append({id: backend.photos[i].id})
                            }
                        }
                    }
                    visible: selectedPhotoIds.count === 0 || selectedPhotoIds.count < (backend ? backend.photos.length : 0)
                }
                
                Button {
                    text: "Снять выделение"
                    onClicked: selectedPhotoIds.clear()
                    visible: selectedPhotoIds.count > 0
                }
                
                Button {
                    text: "Удалить выбранные"
                    onClicked: {
                        if (selectedPhotoIds.count > 0) {
                            deletePhotoPopup.photoIds = []
                            for (var i = 0; i < selectedPhotoIds.count; i++) {
                                deletePhotoPopup.photoIds.push(selectedPhotoIds.get(i).id)
                            }
                            deletePhotoPopup.photoCount = selectedPhotoIds.count
                            deletePhotoPopup.open()
                        }
                    }
                    visible: selectedPhotoIds.count > 0
                }
                
                Button {
                    text: "Назначить категорию"
                    onClicked: {
                        if (selectedPhotoIds.count > 0) {
                            categorySelectPopup.photoIds = []
                            for (var i = 0; i < selectedPhotoIds.count; i++) {
                                categorySelectPopup.photoIds.push(selectedPhotoIds.get(i).id)
                            }
                            categorySelectPopup.photoCount = selectedPhotoIds.count
                            categorySelectPopup.open()
                        }
                    }
                    visible: selectedPhotoIds.count > 0
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Размер миниатюр:"
                    font.pixelSize: 12
                    color: "#7f8c8d"
                }
                
                Button {
                    id: zoomOutButton
                    text: "–"
                    width: 30
                    height: 30
                    font.pixelSize: 16
                    font.bold: true
                    enabled: mainContainer.thumbnailScaleIndex > 0
                    onClicked: {
                        if (mainContainer.thumbnailScaleIndex > 0) {
                            mainContainer.thumbnailScaleIndex--
                        }
                    }
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.down ? "#bdc3c7" : parent.hovered ? "#ecf0f1" : "white") : "#ecf0f1"
                        radius: 4
                        border.width: 1
                        border.color: parent.enabled ? "#bdc3c7" : "#d5dbdb"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: parent.enabled ? "#2c3e50" : "#95a5a6"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Text {
                    text: {
                        var scales = [0.6, 0.8, 1.0, 1.2, 1.4]
                        return Math.round(scales[mainContainer.thumbnailScaleIndex] * 100) + "%"
                    }
                    font.pixelSize: 12
                    font.bold: true
                    color: "#2c3e50"
                    width: 40
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Button {
                    id: zoomInButton
                    text: "+"
                    width: 30
                    height: 30
                    font.pixelSize: 16
                    font.bold: true
                    enabled: mainContainer.thumbnailScaleIndex < 4
                    onClicked: {
                        if (mainContainer.thumbnailScaleIndex < 4) {
                            mainContainer.thumbnailScaleIndex++
                        }
                    }
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.down ? "#bdc3c7" : parent.hovered ? "#ecf0f1" : "white") : "#ecf0f1"
                        radius: 4
                        border.width: 1
                        border.color: parent.enabled ? "#bdc3c7" : "#d5dbdb"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: parent.enabled ? "#2c3e50" : "#95a5a6"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Rectangle {
            id: mainContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f5f5f5"
            
            property int thumbnailScaleIndex: 1
            property var thumbnailScales: [0.6, 0.8, 1.0, 1.2, 1.4]
            property real currentThumbnailScale: thumbnailScales[thumbnailScaleIndex]
            property int baseThumbnailWidth: 180
            property int currentThumbnailWidth: Math.round(baseThumbnailWidth * currentThumbnailScale)
            property int minItemWidth: 120
            property int maxItemWidth: 350
            property int calculatedItemWidth: {
                var width = currentThumbnailWidth
                return Math.max(minItemWidth, Math.min(width, maxItemWidth))
            }
            property int refreshTrigger: 0
            
            onThumbnailScaleIndexChanged: {
                refreshTrigger++
                Qt.callLater(function() {
                    updateGridLayout()
                })
            }
            
            function updateGridLayout() {
                if (flickable) {
                    flickable.contentHeight = Math.max(flowContainer.height, flickable.height)
                }
            }
            
            ListModel {
                id: selectedPhotoIds
                
                function contains(id) {
                    for (var i = 0; i < count; i++) {
                        if (get(i).id === id) return true
                    }
                    return false
                }
                
                function toggle(id) {
                    if (contains(id)) {
                        remove(id)
                    } else {
                        append({id: id})
                    }
                }
                
                function remove(id) {
                    for (var i = 0; i < count; i++) {
                        if (get(i).id === id) {
                            remove(i)
                            return
                        }
                    }
                }
            }
            
            Item {
                anchors.fill: parent
                
                Flickable {
                    id: flickable
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: scrollBar.left
                    anchors.margins: 10
                    
                    contentWidth: width
                    contentHeight: Math.max(flowContainer.height, height)
                    clip: true
                    
                    onWidthChanged: {
                        mainContainer.updateGridLayout()
                    }
                    
                    onHeightChanged: {
                        contentHeight = Math.max(flowContainer.height, height)
                    }
                    
                    Flow {
                        id: flowContainer
                        width: flickable.width
                        spacing: 10
                        
                        Repeater {
                            model: backend ? backend.photos : []
                            
                            delegate: Rectangle {
                                id: photoItem
                                width: {
                                    var containerWidth = flowContainer.width
                                    var spacing = flowContainer.spacing
                                    var itemWidth = mainContainer.calculatedItemWidth
                                    
                                    var columns = Math.max(1, Math.floor(containerWidth / (itemWidth + spacing)))
                                    var availableWidth = containerWidth - (columns - 1) * spacing
                                    var optimalWidth = Math.floor(availableWidth / columns)
                                    
                                    return Math.max(mainContainer.minItemWidth, 
                                                   Math.min(optimalWidth, mainContainer.maxItemWidth))
                                }
                                height: width * 0.78
                                color: selectedPhotoIds.contains(modelData.id) ? "#e3f2fd" : "white"
                                border.color: selectedPhotoIds.contains(modelData.id) ? "#2196f3" : "#ddd"
                                border.width: selectedPhotoIds.contains(modelData.id) ? 2 : 1
                                radius: 5
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#2196f3"
                                    opacity: selectedPhotoIds.contains(modelData.id) ? 0.1 : 0
                                    radius: parent.radius
                                }
                                
                                Rectangle {
                                    visible: selectedPhotoIds.contains(modelData.id)
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "#2196f3"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    spacing: 3
                                    
                                    Rectangle {
                                        width: parent.width
                                        height: parent.height - 36
                                        color: "#f8f9fa"
                                        radius: 3
                                        
                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            source: modelData.qml_path ? modelData.qml_path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            
                                            Rectangle {
                                                visible: !modelData.file_exists || parent.status === Image.Error
                                                anchors.fill: parent
                                                color: "#ecf0f1"
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.file_exists ? "Загрузка..." : "Файл не найден"
                                                    color: "#95a5a6"
                                                    font.pixelSize: 12
                                                }
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: modelData.category && modelData.category.id ? 
                                                   modelData.category.color : "#95a5a6"
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 5
                                        }
                                    }
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 1
                                        
                                        Text {
                                            width: parent.width
                                            text: modelData.filename
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideMiddle
                                        }
                                        
                                        Text {
                                            width: parent.width
                                            text: modelData.category && modelData.category.id ? 
                                                  modelData.category.name : 
                                                  "Без категории"
                                            font.pixelSize: 9
                                            color: modelData.category && modelData.category.id ? 
                                                   modelData.category.color : "#95a5a6"
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            if (!selectedPhotoIds.contains(modelData.id)) {
                                                selectedPhotoIds.clear()
                                                selectedPhotoIds.append({id: modelData.id})
                                            }
                                            
                                            photoContextMenu.photoIds = []
                                            for (var i = 0; i < selectedPhotoIds.count; i++) {
                                                photoContextMenu.photoIds.push(selectedPhotoIds.get(i).id)
                                            }
                                            photoContextMenu.photoCount = selectedPhotoIds.count
                                            photoContextMenu.popup()
                                        } else {
                                            if (mouse.modifiers & Qt.ControlModifier) {
                                                selectedPhotoIds.toggle(modelData.id)
                                            } else if (mouse.modifiers & Qt.ShiftModifier) {
                                                var currentIndex = -1
                                                for (var i = 0; i < backend.photos.length; i++) {
                                                    if (backend.photos[i].id === modelData.id) {
                                                        currentIndex = i
                                                        break
                                                    }
                                                }
                                                
                                                if (selectedPhotoIds.count > 0 && currentIndex !== -1) {
                                                    var lastId = selectedPhotoIds.get(selectedPhotoIds.count - 1).id
                                                    var lastIndex = -1
                                                    for (var j = 0; j < backend.photos.length; j++) {
                                                        if (backend.photos[j].id === lastId) {
                                                            lastIndex = j
                                                            break
                                                        }
                                                    }
                                                    
                                                    var start = Math.min(currentIndex, lastIndex)
                                                    var end = Math.max(currentIndex, lastIndex)
                                                    
                                                    selectedPhotoIds.clear()
                                                    for (var k = start; k <= end; k++) {
                                                        selectedPhotoIds.append({id: backend.photos[k].id})
                                                    }
                                                }
                                            } else {
                                                selectedPhotoIds.clear()
                                                selectedPhotoIds.append({id: modelData.id})
                                            }
                                        }
                                    }
                                    
onDoubleClicked: (mouse) => {
    if (mouse.button === Qt.LeftButton) {
        fullScreenPhotoPopup.photoData = modelData
        fullScreenPhotoPopup.open()
    }
}
                                }
                            }
                        }
                    }
                }
                
                Rectangle {
                    id: scrollBar
                    width: 12
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    color: "#f0f0f0"
                    
                    Rectangle {
                        id: scrollTrack
                        anchors.fill: parent
                        color: "#e0e0e0"
                    }
                    
                    Rectangle {
                        id: scrollThumb
                        width: parent.width
                        height: {
                            if (flickable.contentHeight <= flickable.height) {
                                return parent.height;
                            } else {
                                var thumbHeight = flickable.height / flickable.contentHeight * parent.height;
                                return Math.max(20, thumbHeight);
                            }
                        }
                        x: 0
                        y: {
                            if (flickable.contentHeight <= flickable.height) {
                                return 0;
                            } else {
                                var maxY = parent.height - height;
                                var position = flickable.contentY / (flickable.contentHeight - flickable.height);
                                return position * maxY;
                            }
                        }
                        radius: 6
                        color: scrollMouseArea.pressed ? "#7f8c8d" : 
                               scrollMouseArea.containsMouse ? "#95a5a6" : "#bdc3c7"
                        
                        Behavior on y {
                            enabled: !scrollMouseArea.pressed
                            NumberAnimation { duration: 100 }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    
                    MouseArea {
                        id: scrollMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        property real dragStartY: 0
                        property real thumbStartY: 0
                        property bool dragging: false
                        
                        onPressed: (mouse) => {
                            if (mouse.y >= scrollThumb.y && mouse.y <= scrollThumb.y + scrollThumb.height) {
                                dragStartY = mouse.y
                                thumbStartY = scrollThumb.y
                                dragging = true
                            } else {
                                var newY = mouse.y - scrollThumb.height / 2
                                var maxY = scrollBar.height - scrollThumb.height
                                newY = Math.max(0, Math.min(newY, maxY))
                                
                                var position = newY / maxY
                                flickable.contentY = position * (flickable.contentHeight - flickable.height)
                            }
                        }
                        
                        onReleased: {
                            dragging = false
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed && dragging) {
                                var deltaY = mouse.y - dragStartY
                                var newY = thumbStartY + deltaY
                                var maxY = scrollBar.height - scrollThumb.height
                                newY = Math.max(0, Math.min(newY, maxY))
                                
                                var position = newY / maxY
                                flickable.contentY = position * (flickable.contentHeight - flickable.height)
                            }
                        }
                        
                        onWheel: (wheel) => {
                            flickable.contentY -= wheel.angleDelta.y * 0.5
                            flickable.contentY = Math.max(0, Math.min(flickable.contentY, flickable.contentHeight - flickable.height))
                        }
                    }
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: "Галерея пуста\nНажмите «Добавить фото»"
                font.pixelSize: 16
                color: "#95a5a6"
                horizontalAlignment: Text.AlignHCenter
                visible: backend && backend.photos.length === 0
            }
        }
    }

Popup {
    id: fullScreenPhotoPopup
    modal: true
    focus: true
    width: window.width
    height: window.height
    x: 0
    y: 0
    closePolicy: Popup.CloseOnEscape
    
    background: Rectangle {
        color: "black"
    }
    
    property var photoData: null
    
    Shortcut {
        sequence: "Esc"
        onActivated: fullScreenPhotoPopup.close()
    }
    
    Image {
        id: fullScreenImage
        anchors.fill: parent
        source: fullScreenPhotoPopup.photoData ? fullScreenPhotoPopup.photoData.qml_path : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        
        Rectangle {
            visible: !parent.source || parent.status === Image.Error
            anchors.fill: parent
            color: "#2c3e50"
            
            Text {
                anchors.centerIn: parent
                text: "Изображение не загружено"
                color: "white"
                font.pixelSize: 16
            }
        }
    }
    
    Rectangle {
        id: closeButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 36
        height: 24
        radius: 4
        color: "#ff0000"
        border.width: 1
        border.color: "white"
        z: 1000
        
        Text {
            anchors.centerIn: parent
            text: "×"
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }
        
        MouseArea {
            id: closeMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: fullScreenPhotoPopup.close()
            
            onEntered: {
                closeButton.color = "#ff3333"
                closeButton.border.width = 2
            }
            onExited: {
                closeButton.color = "#ff0000"
                closeButton.border.width = 1
            }
        }
        
        states: [
            State {
                name: "pressed"
                when: closeMouseArea.pressed
                PropertyChanges { 
                    target: closeButton; 
                    color: "#cc0000"
                    scale: 0.95
                }
            }
        ]
        
        transitions: Transition {
            NumberAnimation { properties: "scale, border.width"; duration: 100 }
            ColorAnimation { duration: 100 }
        }
    }
    
    onOpened: forceActiveFocus()
}

    Popup {
        id: categoryPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 500
        height: 450
        
        background: Rectangle {
            color: "white"
            radius: 5
            border.color: "#ddd"
            border.width: 1
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15
            
            Text {
                text: "Управление категориями"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            GroupBox {
                title: "Добавить новую категорию"
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10
                    
                    Text { 
                        text: "Название:" 
                        font.pixelSize: 12
                    }
                    TextField {
                        id: newCategoryName
                        Layout.fillWidth: true
                        placeholderText: "Введите название"
                        font.pixelSize: 12
                    }
                    
                    Text { 
                        text: "Описание:" 
                        font.pixelSize: 12
                    }
                    TextField {
                        id: newCategoryDescription
                        Layout.fillWidth: true
                        placeholderText: "Введите описание (необязательно)"
                        font.pixelSize: 12
                    }
                    
                    Text { 
                        text: "Цвет:" 
                        font.pixelSize: 12
                    }
                    ComboBox {
                        id: colorCombo
                        model: [
                            { name: "Синий", value: "#3498db" },
                            { name: "Зеленый", value: "#2ecc71" },
                            { name: "Красный", value: "#e74c3c" },
                            { name: "Оранжевый", value: "#f39c12" },
                            { name: "Фиолетовый", value: "#9b59b6" },
                            { name: "Серый", value: "#95a5a6" }
                        ]
                        textRole: "name"
                        valueRole: "value"
                        currentIndex: 0
                        Layout.fillWidth: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        text: "Добавить категорию"
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            if (newCategoryName.text.trim()) {
                                backend.add_category(
                                    newCategoryName.text,
                                    newCategoryDescription.text,
                                    colorCombo.currentValue
                                )
                                newCategoryName.text = ""
                                newCategoryDescription.text = ""
                            }
                        }
                    }
                }
            }
            
            GroupBox {
                title: "Существующие категории"
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    
                    ListView {
                        id: categoryList
                        anchors.fill: parent
                        model: backend ? backend.categories.filter(c => c.id !== 0) : []
                        spacing: 5
                        
                        delegate: Rectangle {
                            width: categoryList.width
                            height: 60
                            color: index % 2 === 0 ? "#f8f9fa" : "white"
                            border.color: "#e0e0e0"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10
                                
                                Rectangle {
                                    width: 15
                                    height: 15
                                    radius: 7
                                    color: modelData.color
                                }
                                
                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    RowLayout {
                                        spacing: 5
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 14
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    backend.set_current_category(modelData.id)
                                                    categoryPopup.close()
                                                }
                                            }
                                        }
                                        
                                        Rectangle {
                                            Layout.preferredWidth: 25
                                            Layout.preferredHeight: 18
                                            radius: 9
                                            color: modelData.color
                                            opacity: 0.2
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: {
                                                    var count = 0
                                                    for (var i = 0; i < backend.photos.length; i++) {
                                                        if (backend.photos[i].category && 
                                                            backend.photos[i].category.id === modelData.id) {
                                                            count++
                                                        }
                                                    }
                                                    return count
                                                }
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: modelData.color
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: modelData.description || "Нет описания"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                    }
                                }
                                
                                RowLayout {
                                    spacing: 5
                                    Layout.alignment: Qt.AlignRight
                                    
                                    Button {
                                        text: "✎"
                                        width: 40
                                        height: 30
                                        font.pixelSize: 12
                                        ToolTip.text: "Редактировать категорию"
                                        ToolTip.visible: hovered
                                        
                                        onClicked: {
                                            editCategoryPopup.openWithCategory(modelData)
                                        }
                                        
                                        background: Rectangle {
                                            color: parent.down ? "#3498db" : parent.hovered ? "#2980b9" : "#3498db"
                                            radius: 3
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: "white"
                                            font: parent.font
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                    
                                    Button {
                                        text: "Удалить"
                                        width: 80
                                        height: 30
                                        visible: modelData.id !== 0
                                        onClicked: {
                                            backend.delete_category(modelData.id)
                                        }
                                        
                                        background: Rectangle {
                                            color: parent.down ? "#e74c3c" : parent.hovered ? "#c0392b" : "#e74c3c"
                                            radius: 3
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: "white"
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Нет категорий"
                            color: "#95a5a6"
                            visible: categoryList.count === 0
                        }
                    }
                }
            }
            
            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignRight
                onClicked: categoryPopup.close()
            }
        }
    }

    Component.onCompleted: {
        if (backend) {
            backend.update_categories()
            backend.update_photos(0)
        }
    }
}
