cmake_minimum_required(VERSION 3.21)

project(threadview VERSION 0.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets OpenGLWidgets)

qt_add_executable(threadview
    main.cpp
    mainwindow.cpp
    mainwindow.h
    mainwindow.ui
    stlwidget.cpp
    stlwidget.h
    resources.qrc
)

target_link_libraries(threadview PRIVATE
    Qt6::Widgets
    Qt6::OpenGLWidgets
)

install(TARGETS threadview
    RUNTIME DESTINATION bin
)

# Flathub desktop integration
install(FILES org.oneal.threadview.desktop
        DESTINATION share/applications)
install(FILES org.oneal.threadview.metainfo.xml
        DESTINATION share/metainfo)
install(FILES org.oneal.threadview.svg
        DESTINATION share/icons/hicolor/scalable/apps)
