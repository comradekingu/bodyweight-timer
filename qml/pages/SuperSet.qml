import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import "../js/database.js" as DB
import "../js/global_functions.js" as AppFunctions

Page{
    id: exercisePage

    // property from lower stack page
    property variant    page
    property variant    title

    onStatusChanged: {
        if(status === PageStatus.Activating) {
            DB.getDatabaseValuesFor(page, function (columValues) {
                exercisePage.timePerSet = columValues.value1.value
                exercisePage.setsPerExercise = columValues.value2.value
                exercisePage.roundsPerExercise = columValues.value3.value

                appWindow.exerciseActive = true
                appWindow.activeExercisePageName = page
                appWindow.activeExercisePageTitle = title
            })
        }
    }

    //##    page internal properties
    // current time
    property int currentTime
    property int timePerSet

    onTimePerSetChanged: {
        AppFunctions.resetCurrentTime();
        appWindow.maximalTime = timePerSet;
    }
    onCurrentTimeChanged: appWindow.currentTime = currentTime

    // current set of an exercise
    property int currentSet
    property int setsPerExercise

    onSetsPerExerciseChanged: {
        AppFunctions.resetCurrentSet();
        appWindow.maximalSetNumber = setsPerExercise;
    }
    onCurrentSetChanged: appWindow.currentSetNumber = currentSet

    // current round from high to low
    property int currentRound
    property int roundsPerExercise

    onRoundsPerExerciseChanged: {
        AppFunctions.resetCurrentRound();
        appWindow.maximalExerciseNumber = roundsPerExercise;
    }
    onCurrentRoundChanged: appWindow.currentExerciseNumber = currentRound
    ////

    SilicaFlickable {
        id: flickerList
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("settings")
                onClicked: pageStack.push(Qt.resolvedUrl("ExerciseSettings.qml"), {page: page, title: title})
            }
        }

        PageHeader {
            id: header
            title: exercisePage.title
        }

        Audio {
            id: singleBell
            source: "sound/single_boxing-bell.wav"
        }
        Audio {
            id: doubleBell
            source: "sound/double_boxing-bell.wav"
        }
        Audio {
            id: trippleBell
            source: "sound/tripple_boxing-bell.wav"
        }

        Label {
            id: timerAsNumber
            color: Theme.highlightColor
            anchors.centerIn: progressCircle.Center
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : -(Theme.itemSizeMedium)
            font.pixelSize: Theme.fontSizeHuge
            text: {
                var displayMinutes = Math.floor(currentTime/60);
                var displaySeconds = currentTime-(displayMinutes*60)
                //: m = minute, s = second
                qsTr("%1m %2s").arg(displayMinutes).arg(displaySeconds)
            }
        }

        ProgressCircle {
            id: progressCircle
            scale: 4.5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : -(Theme.itemSizeMedium)
            progressColor: Theme.highlightColor
            backgroundColor: Theme.highlightDimmerColor
            Timer {
                id: progressCircleTimer
                interval: 1000
                repeat: true
                running: appWindow.timerRunning
                triggeredOnStart: true
                onTriggered: {
                    //init
                    if(exercisePage.currentTime === exercisePage.timePerSet) {
                        var secondsOfCurrentTime = (exercisePage.timePerSet % 60);
                        progressCircle.value = (100-(0.01666666667 * secondsOfCurrentTime));
                    }
                    //calc the current time
                    progressCircle.value = (progressCircle.value + 0.01666666667) % 1.0;
                    exercisePage.currentTime -= 1;

                    //no more remaining sets for this exercise?
                    if(currentSet > setsPerExercise) {
                        currentRound += 1;
                        if(currentRound > roundsPerExercise) {
                            trippleBell.play();
                            AppFunctions.resetTimerWithTimeSetRound();
                        } else {
                            doubleBell.play();
                            AppFunctions.restartTimerAndSet();
                            AppFunctions.timerTogglePause();
                        }
                    } else {
                        //reset timer and remove 1 of a set
                        if(exercisePage.currentTime === 0) {
                            exercisePage.currentSet += 1;
                            if(currentSet <= setsPerExercise) {
                                singleBell.play();
                            }
                            AppFunctions.restartTimer();
                        }
                    }
                }
            }
        }

        Label {
            id:currentRoundDisplay
            color: Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : (Theme.itemSizeMedium)+progressCircle.height
            font.pixelSize: Theme.fontSizeMedium
            text: {
                if(progressCircleTimer.running || appWindow.timerStartedOnce) {
                   if(currentSet <= setsPerExercise) {
                       qsTr("current set: %1 of %2").arg(currentSet).arg(setsPerExercise)
                   }
                   else {
                       qsTr("current set: %1 of %2").arg(setsPerExercise).arg(setsPerExercise)
                   }
                } else {
                   qsTr("sets for each exercise: %1").arg(setsPerExercise)
               }
            }
        }
        Label {
            id:currentExerciseDisplay
            color: Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: currentRoundDisplay.bottom
            font.pixelSize: Theme.fontSizeMedium
            text: {
                if(progressCircleTimer.running || appWindow.timerStartedOnce) {
                    qsTr("current exercise: %1 of %2").arg(currentRound).arg(roundsPerExercise)                }
                else { 
                    qsTr("number of exercises: %1").arg(roundsPerExercise)
                }
            }
        }


        Button {
            anchors.top: currentExerciseDisplay.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Theme.paddingLarge
            onClicked: AppFunctions.timerTogglePause()
            text: {
                if(progressCircleTimer.running) {
                   qsTr("pause")
                }
                else {
                    if(appWindow.timerStartedOnce) {
                        qsTr("resume")
                    }
                    else {
                        qsTr("start")
                    }
                }
            }
        }
    }
}
