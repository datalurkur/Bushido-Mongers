#include "util/geom.h"
#include "util/log.h"
#include "util/vector.h"
#include "curseme/curseme.h"
#include "curseme/renderer.h"

#include <unistd.h>
#include <signal.h>

char* renderData = 0;

void cleanup(int signal) {
  CurseMeTeardown();
  Log::Teardown();

  if(renderData) {
    free(renderData);
    renderData = 0;
  }

  exit(signal);
}

void setup() {
  Log::Setup("stdout");
  CurseMeSetup();
  signal(SIGINT, cleanup);
}

int main() {
  setup();

  // Set up our renderer to fill the whole screen
  int maxX, maxY;
  getmaxyx(stdscr, maxY, maxX);
  AsciiRenderer renderer(0, 0, maxX, maxY);

  int plotSize = 40;

  renderData = (char*)malloc(plotSize * plotSize * sizeof(char));

  wrefresh(stdscr);

  IVec2 center(15, 15);
  int numCircles = 5;
  // Perform circle generation tests
  int c;
  for(c = 0; c < numCircles; c++) {
    int radius = 2 * c + 1;
    memset(renderData, '.', plotSize * plotSize);
    list<IVec2> circle;
    computeRasterizedCircle(radius, circle);
    for(auto rPoint : circle) {
      IVec2 point = rPoint + center;
      if(point.x < 0 || point.x >= plotSize || point.y < 0 || point.y >= plotSize) { continue; }
      renderData[(point.y * plotSize) + point.x] = 'O';
    }
    renderer.setInputData(renderData, plotSize, plotSize);
    renderer.render();
    sleep(1);
  }

  // Perform line generation tests
  IVec2 start(2, 4),
        end(25, 20);
  list<IVec2> line;
  computeRasterizedLine(start, end, line);
  for(c = 0; c < (int)line.size(); c++) {
    int d = 0;
    memset(renderData, '.', plotSize * plotSize);
    for(auto point : line) {
      if(d > c) { break; }
      d++;
      renderData[(point.y * plotSize) + point.x] = 'O';
    }
    renderer.setInputData(renderData, plotSize, plotSize);
    renderer.render();
    sleep(1);
  }

  // Perform circle filled using lines test
  memset(renderData, '.', plotSize * plotSize);
  int radius = 12;
  list<IVec2> disc;
  computeRasterizedDisc(radius, disc);
  disc.sort(magnitudeGreater<IVec2>);

  set<IVec2> visited;
  set<IVec2> obstacles{
    IVec2(10, 10),
    IVec2(13, 17),
    IVec2(14, 17),
    IVec2(18, 15),
    IVec2(19, 15),
    IVec2(20, 15),
    IVec2(20, 16)
  };
  set<IVec2> visible;

  for(auto rPoint : disc) {
    IVec2 point = center + rPoint;
    Info("Checking for visibility of " << point);
    if(visited.find(point) != visited.end()) {
      Info("Point " << point << " already visited");
      continue;
    }
    list<IVec2> lineOfSight;
    computeRasterizedLine(center, point, lineOfSight);

    bool obstructed = false;
    for(auto linePoint : lineOfSight) {
      Info("\tWalking to " << linePoint);
      auto visitedResult = visited.insert(linePoint);

      if(!obstructed && visitedResult.second) {
        Info("\t\tPoint is not obstructed and has not been visited");
        visible.insert(linePoint);
      } else if(obstructed) {
        Info("\t\tPoint is obstructed");
      } else {
        Info("\t\tPoint has been visited");
      }

      auto obstacleData = obstacles.find(linePoint);
      if(obstacleData != obstacles.end()) {
        Info("\t\tPoint obstructs further view!");
        obstructed = true;
      }
    }
  }

  for(auto rPoint : disc) {
    IVec2 point = rPoint + center;
    if(point.x < 0 || point.y < 0 || point.x >= plotSize || point.y >= plotSize) { continue; }
    int index = (point.y) * plotSize + point.x;
    bool isVisible = (visible.find(point) != visible.end()),
         isObstacle = (obstacles.find(point) != obstacles.end());
    if(isVisible) {
      if(isObstacle) {
        renderData[index] = 'X';
      } else {
        renderData[index] = 'o';
      }
    } else {
      if(isObstacle) {
        renderData[index] = '@';
      } else {
        renderData[index] = '-';
      }
    }
  }

  renderer.setInputData(renderData, plotSize, plotSize);
  renderer.render();
  sleep(5);

  cleanup(0);
}
