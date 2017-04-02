#include <QtQuick>

#include <sailfishapp.h>

int main(int argc, char *argv[])
{
    QGuiApplication *app = SailfishApp::application(argc, argv);
    QQuickView *view = SailfishApp::createView();

    view->setSource(SailfishApp::pathTo("qml/harbour-bodyweighttimer.qml"));

    view->showFullScreen();
    app->exec();
}
