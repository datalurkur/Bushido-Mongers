#include "util/geom.h"
#include "util/log.h"
#include "util/vector.h"
#include "curseme/curseme.h"
#include "curseme/renderer.h"

#include <unistd.h>
#include <signal.h>

RenderSource* renderSource = 0;

void cleanup(int signal) {
  CurseMeTeardown();
  Log::Teardown();

  if(renderSource) {
    delete renderSource;
    renderSource = 0;
  }

  exit(signal);
}

void setup() {
  Log::Setup("stdout");
  CurseMeSetup();
  init_pair(1, COLOR_RED, COLOR_BLACK);
  signal(SIGINT, cleanup);
}

int main() {
  setup();

  // Set up our renderer to fill the whole screen
  int maxX, maxY;
  getmaxyx(stdscr, maxY, maxX);
  renderSource = new RenderSource(maxX - 2, maxY - 2);
  RenderTarget renderTarget(stdscr, renderSource);
  renderTarget.setOffset(IVec2(1, 1));

  int plotSize = 40;

  wrefresh(stdscr);

  IVec2 center(15, 15);
  int numCircles = 2;
  // Perform circle generation tests
  int c;
  for(c = 0; c < numCircles; c++) {
    int radius = 4 * c + 1;
    list<IVec2> circle;
    computeRasterizedCircle(radius, circle);

    renderSource->setData('.', A_NORMAL);
    for(auto rPoint : circle) {
      IVec2 point = rPoint + center;
      if(point.x < 0 || point.x >= plotSize || point.y < 0 || point.y >= plotSize) { continue; }
      renderSource->setData(point.x, point.y, 'O', A_BOLD);
    }
    renderTarget.render();
    sleep(1);
  }

  // Perform line generation tests
  IVec2 start(1, 1),
        end(2, 4);
  list<IVec2> line;
  computeRasterizedLine(start, end, line);
  for(c = 0; c < (int)line.size(); c++) {
    int d = 0;
    renderSource->setData('.', A_NORMAL);
    for(auto point : line) {
      if(d > c) { break; }
      d++;
      renderSource->setData(point.x, point.y, 'O', A_BOLD);
    }
    renderTarget.render();
    sleep(1);
  }

  // Perform circle filled using lines test
  renderSource->setData('.', A_NORMAL);
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
    bool isVisible = (visible.find(point) != visible.end()),
         isObstacle = (obstacles.find(point) != obstacles.end());
    if(isVisible) {
      if(isObstacle) {
        renderSource->setData(point.x, point.y, 'O', A_NORMAL);
      } else {
        renderSource->setData(point.x, point.y, '_', A_NORMAL);
      }
    } else {
      if(isObstacle) {
        renderSource->setData(point.x, point.y, 'O', A_DIM | COLOR_PAIR(1));
      } else {
        renderSource->setData(point.x, point.y, '_', A_DIM | COLOR_PAIR(1));
      }
    }
  }

  renderTarget.render();
  sleep(5);

  cleanup(0);
}
