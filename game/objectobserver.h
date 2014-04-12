#ifndef OBJECT_OBSERVER_H
#define OBJECT_OBSERVER_H

class ObjectObserver {
public:
  ObjectObserver();
  ~ObjectObserver();

  bool isObjectUpToDate(BObjectID id);

  void createOrUpdateObject();

  BObject* getObject(BObjectID id);

private:
  BObjectMap _objectMap;
};

#endif
