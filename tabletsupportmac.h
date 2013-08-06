#pragma once

#include <QAbstractNativeEventFilter>

class QWidget;

class TabletSupport : public QAbstractNativeEventFilter
{
public:
	explicit TabletSupport(QWidget *window);
	~TabletSupport();
	
	void start();
	void stop();
	
signals:
	
public slots:
	
protected:
	
	bool nativeEventFilter(const QByteArray &eventType, void *message, long *result) override;
	
private:
	
	struct DeviceData;
	
	struct Data;
	Data *d;
};
