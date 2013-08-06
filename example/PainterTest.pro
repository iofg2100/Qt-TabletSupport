#-------------------------------------------------
#
# Project created by QtCreator 2012-10-19T23:35:51
#
#-------------------------------------------------

cache()

QT       += core gui concurrent

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = PainterTest
TEMPLATE = app
CONFIG += c++11

mac {
	CONFIG += objective_c
	QMAKE_LFLAGS += -lobjc -framework Cocoa
}

SOURCES += main.cpp\
        widget.cpp

win32 {
	SOURCES += ../tabletsupport.cpp
}

mac {
	OBJECTIVE_SOURCES += ../tabletsupportmac.mm
}

HEADERS  += widget.h \
    ../tabletsupport.h \
    ../wintabapi.h \
    ../wintab.h \
    ../pktdef.h \
    ../tabletsupportmac.h
