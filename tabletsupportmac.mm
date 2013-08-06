#import <Cocoa/Cocoa.h>
#include <QDebug>
#include <QWidget>
#include <QTabletEvent>
#include <QAbstractEventDispatcher>
#include <QApplication>

#include "tabletsupportmac.h"

struct TabletSupport::DeviceData
{
	QTabletEvent::TabletDevice deviceType = QTabletEvent::Stylus;
	QTabletEvent::PointerType pointerType = QTabletEvent::Pen;
	qint64 uniqueId = 0;
};

struct TabletSupport::Data
{
	QWidget *window = nullptr;
	DeviceData deviceData;
	bool inProximity = false;
};

TabletSupport::TabletSupport(QWidget *window) :
	d(new Data)
{
	d->window = window;
}

TabletSupport::~TabletSupport()
{
	stop();
	delete d;
}

void TabletSupport::start()
{
	auto dispacher = QAbstractEventDispatcher::instance(d->window->thread());
	dispacher->installNativeEventFilter(this);
}

void TabletSupport::stop()
{
	auto dispacher = QAbstractEventDispatcher::instance(d->window->thread());
	dispacher->removeNativeEventFilter(this);
}

bool TabletSupport::nativeEventFilter(const QByteArray &eventType, void *message, long *result)
{
	Q_UNUSED(eventType);
	Q_UNUSED(result);
	
	auto theEvent = reinterpret_cast<NSEvent *>(message);
	
	auto type = [theEvent type];
	
	switch (type)
	{
		case NSTabletProximity:
		{
			bool entering = [theEvent isEnteringProximity];
			
			if (entering)
			{
				DeviceData dev;
				dev.uniqueId = [theEvent uniqueID];
				
				// set pointer type
				switch ([theEvent pointingDeviceType])
				{
					default:
						dev.pointerType = QTabletEvent::UnknownPointer;
						break;
					case NSPenPointingDevice:
						dev.pointerType = QTabletEvent::Pen;
						break;
					case NSCursorPointingDevice:
						dev.pointerType = QTabletEvent::Cursor;
						break;
					case NSEraserPointingDevice:
						dev.pointerType = QTabletEvent::Eraser;
						break;
				}
				
				// TODO: support device type
				
				d->deviceData = dev;
			}
			
			QTabletEvent qEvent(
						entering ? QEvent::TabletEnterProximity : QEvent::TabletLeaveProximity,
						QPointF(),
						QPointF(),
						d->deviceData.deviceType,
						d->deviceData.pointerType,
						0, 0, 0, 0, 0, 0, 0,
						d->deviceData.uniqueId);
			
			qApp->sendEvent(qApp, &qEvent);
			
			d->inProximity = entering;
			
			return true;
		}
		case NSMouseMoved:
		case NSLeftMouseDown:
		case NSRightMouseDown:
		case NSLeftMouseUp:
		case NSRightMouseUp:
		case NSTabletPoint:
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		{
			if (!d->inProximity)
				return false;
			
			auto windowPos = [theEvent locationInWindow];
			auto window = [theEvent window];
			auto localPos = [[window contentView] convertPoint: windowPos fromView: nil];
			auto globalPos = [window convertBaseToScreen: windowPos];
			
			QPointF localQPos(localPos.x, localPos.y);
			//if (!QRect(QPoint(), d->window->geometry().size()).contains(localQPos.toPoint()))
			//	return false;
			
			auto offset = d->window->mapTo(d->window->topLevelWidget(), QPoint());
			localQPos -= offset;
			
			QEvent::Type qType;
			switch (type)
			{
				case NSLeftMouseDown:
				case NSRightMouseDown:
					qType = QEvent::TabletPress;
					break;
				case NSLeftMouseUp:
				case NSRightMouseUp:
					qType = QEvent::TabletRelease;
					break;
				default:
					qType = QEvent::TabletMove;
					break;
			}
			
			qreal pressure = [theEvent pressure];
			
			auto tilt = [theEvent tilt];
			auto xTilt = qRound(tilt.x * 60.0);
			auto yTilt = qRound(tilt.y * -60.0);
			
			QTabletEvent qEvent(qType,
				localQPos,
				QPointF(globalPos.x, globalPos.y),
				d->deviceData.deviceType,
				d->deviceData.pointerType,
				pressure, xTilt, yTilt, 0, 0, 0,
				0,
				d->deviceData.uniqueId);
			
			return qApp->sendEvent(d->window, &qEvent);
		}
		default:
			return false;
	}
}


