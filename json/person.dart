class MsPropcircleworkList {
  String? articletitle;

  String? articletags;
}

class Data {
  List<MsPropcircleworkList>? msPropcircleworkList;
}

class Citys {
  String? dd;
}

class Body {
  String? code;

  Data? data;

  List<List<List<Citys>>>? citys;
}

class Person {
  Body? body;
}

