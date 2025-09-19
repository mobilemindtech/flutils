
import 'dart:async';
import 'dart:io';

import 'package:flutils/misc/app_get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';


class OrmCriteria{
  String columnName;
  dynamic value;
  String operation;
  String native;
  List args;

  OrmCriteria({this.columnName = "", this.value, this.operation = "=", this.native = "", this.args = const []});
}

class OrmOrder{
  String sort;
  String order;

  OrmOrder(this.sort, {this.order = "asc"});
}

class OrmFilter {
  List<OrmCriteria> criterias = [];
  List<String> joins =  [];
  int offset = 0;
  int limit = 0;
  List<OrmOrder> orders = [];

  bool select = false;
  bool delete = false;
  bool update = false;
  bool count = false;

  OrmFilter({
    this.select = true,
    this.delete = false,
    this.update = false,
    this.offset = 0,
    this.limit = 0});

  factory OrmFilter.initWithCriteria(OrmCriteria criteria) => OrmFilter().addCriteria(criteria);

  factory OrmFilter.initWithCriterias(List<OrmCriteria> criterias) => OrmFilter().addCriterias(criterias);

  OrmFilter addCriteria(OrmCriteria criteria) {
    this.criterias.add(criteria);
    return this;
  }

  OrmFilter addCriterias(List<OrmCriteria> criteria) {
    this.criterias.addAll(criterias);
    return this;
  }
}


enum OrmColumnType{
  Text,
  Int,
  Num,
  Date,
  DateTime,
  Bool,
  Enum,
  Relation,
  List,
  None
}

class OrmColumn{
  bool primaryKey;
  String name;
  bool unique;
  bool nullable;
  bool autoIncrement;
  String? defaultValue;
  OrmColumnType type;
  String listRelName = "";
  List enumValues;
  String dbTypeName = "";
  bool eager;
  bool cascadeOnInsertOrUpdate;
  bool cascadeOnDelete;

  OrmColumn({
    this.primaryKey = false,
    this.name = "",
    this.unique = false,
    this.nullable = true,
    this.defaultValue,
    this.type = OrmColumnType.None,
    this.autoIncrement = false,
    this.eager = false,
    this.cascadeOnInsertOrUpdate = false,
    this.cascadeOnDelete = false,
    this.enumValues = const []
  });
}

abstract class OrmModel<T> {

  static OrmManager? ormManager;

  int id = 0;
  List<OrmColumn> columns = const [];
  String tableName = "";

  OrmModel({this.id = 0}){
    this.tableName = this.getTableName();
    this.columns = <OrmColumn>[
      new OrmColumn(
          nullable: false,
          primaryKey: true,
          name: "id",
          type: OrmColumnType.Int,
          autoIncrement: true
      )
    ];

    var cols = this.getColumns();
    this.columns.addAll(cols);

    if(ormManager == null) {
      ormManager = new OrmManager();
      ormManager!.init();
    }
  }

  bool isNew(){
    return this.id == 0;
  }

  String getTableName();
  List<OrmColumn> getColumns();
  void setColumnValue(String name, dynamic value);
  dynamic getColumnValue(String name);

  OrmModel modelFactory();
  OrmModel? relationFactory(String name){ return null; }

  Map toMap(){
    Map data = new Map();
    for(var column in this.columns){
      data[column.name] = this.getColumnValue(column.name);
    }
    return data;
  }

  void fromMap(Map map){
    map.forEach((key, value){
      this.setColumnValue(key, value);
    });
  }

  Future withTransaction(f(Database db)) async {


    await OrmManager.cacheControl(() async{

      ormManager!.executeWithTransaction((database){
        return f(database);
      });

    });

  }

  Future persist({Database? db}) async {

    await OrmManager.cacheControl(() async{
      await _persistRelations(db: db);

      if (this.isNew()) {
        return await this._save(db: db);
      } else {
        return await this._update(db: db);
      }

    });
  }

  Future _save({Database? db}) async{
    await OrmManager.cacheControl(() async{
      var result = ormManager!.createInsertQuery(this);
      var query = result["query"] as String;
      var args = result["args"] as List;
      this.id = await ormManager!.executeInsert(query, args: args, db: db);
    });
  }

  Future _update({Database? db}) async{
    await OrmManager.cacheControl(() async {
      var result = ormManager!.createUpdateQuery(this);
      var query = result["query"] as String;
      var args = result["args"] as List;
      await ormManager!.executeUpdate(query, args: args, db: db);
    });
  }

  Future delete({OrmFilter? filter, Database? db}) async{

    await OrmManager.cacheControl(() async {

      await _deleteDependencies();

      if (filter == null) {
        var query = "delete from ${this.tableName} where id = ?";
        await ormManager!.executeDelete(query, args: [this.id]);
      } else {
        var result = ormManager!.createFilterQuery(this, filter);
        var query = result["query"] as String;
        var args = result["args"] as List;
        await ormManager!.executeDelete(query, args: args);
      }
    });



  }

  Future<List<T>> list({bool loadDependencies = true}) async{

    List<T> list = <T>[];

    await OrmManager.cacheControl(() async {
      var query = "select * from ${this.tableName}";
      var results = await ormManager!.executeQuery(query);

      for (var result in results) {
        var m = this.modelFactory();
        await ormManager!._resultToModel(result, m);
        if(loadDependencies)
          await m._loadDependencies();
        list.add(m as T);
      }

    });

    return list;
  }

  Future load({bool loadDependencies = true}) async{
    await OrmManager.cacheControl(() async {
      var query = "select * from ${this.tableName} where id = ?";
      var results = await ormManager!.executeQuery(query, args: [this.id]);

      if (results.isNotEmpty) {
        var result = results[0];
        await ormManager!._resultToModel(result, this);
        if(loadDependencies)
          await _loadDependencies();
      }
    });

  }

  Future<int> count({OrmFilter? filter}) async{

    if(filter == null) {
      var query = "select count(id) from ${this.tableName} ";
      return await ormManager!.executeCount(query);
    }else{
      var result = ormManager!.createFilterQuery(this, filter);
      var query = result["query"] as String;
      var args = result["args"] as List;
      return await ormManager!.executeCount(query, args: args);
    }
  }

  Future<T?> executeResultTransformer(String query, [List? args, bool loadDependencies = false]) async{
    var m = this.modelFactory();
    await ormManager!.executeNativeResultTransformer(m, query, args);

    if(m.isNew())
      return null;

    if(loadDependencies)
      await m._loadDependencies();

    return m as T;
  }

  Future<List<T>> executeResultsTransformer(String query, [List? args, bool loadDependencies = false]) async{

    List<T> list = <T>[];
    var m = this.modelFactory();

    var results = await ormManager!.executeNativeResultsTransformer(m, query, args: args);

    for(var result in results){
      list.add(result as T);

      if(loadDependencies)
        await result._loadDependencies();
    }

    return list;
  }

  Future<T?> findOne(OrmFilter filter, {bool loadDependencies = true}) async{

    var m = this.modelFactory();
    var result =  ormManager!.createFilterQuery(this, filter);
    var query = result["query"] as String;
    var args = result["args"] as List;

    var results = await ormManager!.executeQuery(query,args: args);

    if(results.isNotEmpty){
      var it = results[0];
      await ormManager!._resultToModel(it, m);

      if(loadDependencies)
        await m._loadDependencies();

      return m as T;
    }

    return null;
  }

  Future<List<T>> find(OrmFilter filter, {bool loadDependencies = true}) async{

    List<T> list = <T>[];
    var result = ormManager!.createFilterQuery(this, filter);
    var query = result["query"] as String;
    var args = result["args"] as List;

    var results = await ormManager!.executeQuery(query,args: args);

    for (var it in results) {
      var m = this.modelFactory();
      await ormManager!._resultToModel(it, m);

      if(loadDependencies)
        await m._loadDependencies();

      list.add(m as T);
    }

    return list;
  }

  Future _persistRelations({Database? db}) async{
    for(var it in this.columns){
      if(it.type == OrmColumnType.Relation && it.cascadeOnInsertOrUpdate){

        var obj = this.getColumnValue(it.name);

        if(obj is OrmModel){
          if(!obj.isNew()) {

            var key = "${obj.runtimeType.toString()}#${obj.id}";
            if(OrmManager.cache.containsKey(key))
              continue;

          }else {

            await obj.persist(db: db);
            var key = "${obj.runtimeType.toString()}#${obj.id}";
            OrmManager.cache[key] = obj;

          }
        }

      }else if(it.type == OrmColumnType.List && it.cascadeOnInsertOrUpdate){
        var objs = this.getColumnValue(it.name);

        if(objs is List){
          var list = objs;

          for(var obj in list){
            var rel = obj as OrmModel;
            await rel.persist(db: db);
          }
        }
      }
    }
  }

  Future _loadDependencies() async{
    for(var it in this.columns){
      if(it.type == OrmColumnType.Relation && it.eager){

        var obj = this.getColumnValue(it.name);

        if(obj is OrmModel){
          var rel = obj;
          if(!rel.isNew()) {

            var key = "${rel.runtimeType.toString()}#${rel.id}";
            if(OrmManager.cache.containsKey(key))
              continue;

            await rel.load();
          }
        }

      }else if(it.type == OrmColumnType.List && it.eager){

        var listTypeModel = this.relationFactory(it.name)!;

        var key = "${listTypeModel.runtimeType.toString()}#list#${this.id}";
        if(OrmManager.cache.containsKey(key)) {
          this.setColumnValue(it.name, OrmManager.cache[key]);
          continue;
        }

        var listResults = await listTypeModel.find(OrmFilter().addCriteria(
            OrmCriteria(
                columnName: it.listRelName,
                value: this.id
            )
        ));

        OrmManager.cache[key] = listResults;

        this.setColumnValue(it.name, listResults);
      }
    }
  }

  Future _deleteDependencies({Database? db}) async{
    for(var it in this.columns){
      if(it.type == OrmColumnType.Relation && it.cascadeOnDelete){

        var obj = this.getColumnValue(it.name);

        if(obj is OrmModel){
          var rel = obj;
          if(!rel.isNew()) {

            var key = "${rel.runtimeType.toString()}#${rel.id}";
            if(OrmManager.cache.containsKey(key))
              continue;

            await rel.delete(db: db);
          }
        }

      }else if(it.type == OrmColumnType.List && it.cascadeOnDelete){
        var objs = this.getColumnValue(it.name);

        if(objs is List){
          var list = objs;

          for(var obj in list){
            var rel = obj as OrmModel;
            if(!rel.isNew()) {

              var key = "${rel.runtimeType.toString()}#${rel.id}";
              if(OrmManager.cache.containsKey(key))
                continue;

              await rel.delete(db: db);
            }
          }
        }
      }
    }
  }

  dynamic stringToEnum(String? value, List values){

    dynamic result;

    if(value == null){
      value = values[0];
    }

    result = AppGet.firstWhere(values, (p) =>
    p.toString().split(".")[1].toUpperCase() == value!.toUpperCase()
    );

    if(result == null){
      result = values[0];
    }

    return result;
  }

  String enumToString(dynamic value, List values){

    String? result;

    if(value == null){
      value = values[0].toString().split(".")[1];
    }

    var val = AppGet.firstWhere(values, (p) =>
    p.toString().split(".")[1].toUpperCase() == value.toString().split(".")[1].toUpperCase()
    );

    if (val != null) {
      value = val.toString();
    }

    result = values[0].toString().split(".")[1];

    return result.toString().split(".")[1];
  }
}

class OrmManager {


  static String DATETIME_FORMAT = 'yyyy-MM-dd HH:mm:ss.SSS';
  static String DATE_FORMAT = 'yyyy-MM-dd';
  static String SQL_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S.%f';
  static String SQL_DATE_FORMAT = '%Y-%m-%d';

  static DateFormat datetimeFormat = new DateFormat(DATETIME_FORMAT);
  static DateFormat dateFormat = new DateFormat(DATE_FORMAT);

  static String dbName = "";
  static String databasePath = "";
  static bool debug = false;

  static Map cache = new Map();
  static int deepCount = 0;

  int dbVersion;
  bool resetDb;
  bool createOrUpdateDb;
  List<OrmModel> models;

  static Future cacheControl(f()) async {
    try{
      deepCount++;
      await f();
    }finally{
      deepCount--;
      if(deepCount == 0)
        cache.clear();
    }
  }

  void _debug(args){
    if(debug)
      print("ORM: $args");
  }

  OrmManager({
    this.resetDb = false,
    this.createOrUpdateDb = false,
    this.dbVersion = 1,
    this.models = const []
  });

  Future init({bool debug = false, String dbName = "none"}) async{

    OrmManager.debug = debug;
    OrmManager.dbName = dbName;

    _debug("Init");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    _debug("documentsDirectory.path=${documentsDirectory.path}");
    databasePath = join(documentsDirectory.path, dbName);

    _debug("databasePath=$databasePath");

    if(this.resetDb){
      var dbExists = await new File(databasePath).exists();
      if(dbExists)
        await deleteDatabase(databasePath);
    }

    if(this.createOrUpdateDb){
      await this.createDatabase();
    }
  }

  Future createDatabase() async{

    // open the database
    await openDatabase(databasePath, version: dbVersion,
        onCreate: (Database db, int version) async {
          // When creating the db, create the table
          for(var model in this.models){

            var exists = await this.tableExists(model, db: db);

            if(!exists){
              var query = this._getTableCreateMetadata(model);

              await db.execute(query);

            }else{
              var queries = await this._getTableUpdateMetadata(model, db: db);
              for(var query in queries){
                await db.execute(query);
              }
            }
          }
        }
    );
  }

  Future _execute(Future f(Database db), {Database? db}) async {

    _debug("_execute db == null ? ${db == null}");

    var database = db != null ? db : await openDatabase(databasePath, version: dbVersion);

    try{
      return await f(database);
    }finally{
      if(db == null) {
        if(debug)
          _debug("_execute close db");
        await database.close();
      }else{
        if(debug)
          _debug("_execute not close db");
      }
    }
  }

  Future executeWithTransaction(Future f(Database db), {Database? db}) async{

    _debug("executeWithTransaction db is null ? ${db == null}");
    var database = db != null ? db : await openDatabase(databasePath, version: dbVersion);

    if(db != null){
      return await _execute(f, db: database);
    }else{
      await database.transaction((tx) async {
        try{
          return await f(database);
        }finally{
          _debug("executeWithTransaction close db");
          await database.close();
        }
      });
    }
  }


  Future<List<Map<String, Object?>>> executeQuery(String query, {List? args, Database? db}) async{

    _debug("execute query: $query, args: ${args?.join(",")}");

    return await _execute((database) async{
      return await database.rawQuery(query, args);
    }, db: db);
  }



  Future<int> executeInsert(String query, {List? args, Database? db}) async{

    _debug("execute query: $query, args: ${args?.join(",")}");

    return await _execute((database) async{
      return await database.rawInsert( query, args);
    }, db: db);

  }

  Future<int> executeUpdate(String query, {List? args, Database? db}) async{

    _debug("execute query: $query, args: ${args?.join(",")}");

    return await _execute((database) async{
      return await database.rawUpdate(query, args);
    }, db: db);

  }

  Future<int> executeCount(String query, {List? args, Database? db}) async {

    _debug("execute query: $query, args: ${args?.join(",")}");

    return await _execute((database) async{
      return Sqflite.firstIntValue(await database.rawQuery(query, args));
    }, db: db);

  }

  Future<int> executeDelete(String query, {List? args, Database? db}) async {

    _debug("execute query: $query, args: ${args?.join(",")}");

    return await _execute((database) async{
      return await database.rawDelete(query, args);
    }, db: db);
  }

  String _getColumnType(OrmColumn column) {
    switch (column.type) {
      case OrmColumnType.Text:
        return "text";
      case OrmColumnType.Date:
        return "text";
      case OrmColumnType.DateTime:
        return "text";
      case OrmColumnType.Enum:
        return "text";
      case OrmColumnType.Bool:
        return "int";
      case OrmColumnType.Int:
        return "int";
      case OrmColumnType.Relation:
        return "int";
      case OrmColumnType.Num:
        return "real";
      case OrmColumnType.List:
        _debug("ignore list property to create table");
        return "";
      default:
        return "";
    }
  }

  String _getColumnDefinitions(OrmColumn column){

    var query = "";

    if(!column.nullable)
      query += "not null";

    if(column.defaultValue != null)
      query += "default '" + column.defaultValue! + "'";

    if(column.unique)
      query += "unique";

    if(column.autoIncrement)
      query += "autoincrement";

    return query;
  }

  String _getTableCreateMetadata(OrmModel model){


    var query = "create table " + model.tableName + " ( ";

    for(var j = 0; j < model.columns.length; j++){

      var column = model.columns[j];

      if(column.type == OrmColumnType.List) continue;

      query += column.name;


      if(column.primaryKey){

        query += " integer primary key";

        if(column.autoIncrement)
          query += " autoincrement";

        query += ",";

        continue;
      }

      query += " " + _getColumnType(column);
      query += " " + _getColumnDefinitions(column);


      query += ", ";
    }

    query = query.substring(0, query.length-2);
    query +=  " )";

    _debug("************ table create metadata begin *********************");
    _debug(query);
    _debug("************ table create metadata end *********************");

    return query;
  }

  Future<bool> tableExists(OrmModel model, {Database? db}) async {

    var tableName = model.tableName;


    var query = "select count(name) From sqlite_master Where type='table' And name = '" + tableName + "'";

    _debug("check if table exists: " + query);

    var result = await executeCount(query, db: db);

    return result > 0;
  }


  Future<List<String>> _getTableUpdateMetadata(OrmModel model, {Database? db}) async{


    var queries = <String>[];
    var columns = await _getTableMetadata(model, db: db);


    for(var column in model.columns){

      if(column.type == OrmColumnType.List) continue;

      var columnName = column.name;
      var columnFound = false;

      for(var dbColumn in columns){
        if(columnName == dbColumn.name){
          columnFound = true;
          break;
        }
      }

      if(!columnFound){

        _debug("column " + columnName + " for table" + model.tableName  + " not found ");
        var query = "alter table " + model.tableName + " add " + columnName;

        column.unique = false;
        query += " " + _getColumnType(column);
        query += " " + _getColumnDefinitions(column);

        queries.add(query);
      } else {
        _debug("** column " + columnName + " for table" + model.tableName  + " found ");
      }
    }

    return queries;
  }

  Future<List<OrmColumn>> _getTableMetadata(OrmModel model, {Database? db}) async{

    var tableName = model.tableName;
    var columns = <OrmColumn>[];
    var query = "PRAGMA table_info('" + tableName + "')";

    var results = await executeQuery(query, db: db);


    for(var result in results) {
      var col = new OrmColumn(
          name: result[1] as String,
          nullable: result[3] == 0,
          defaultValue: result[4] as String,
          primaryKey: result[5] == 1
      );

      col.dbTypeName = result[2] as String;
      columns.add(col);
    }

    return columns;
  }

  Future<List<T>> executeNativeResultsTransformer<T extends OrmModel>(T model, String query, {List? args}) async{

    List<T> list = <T>[];

    var results = await executeQuery(query, args: args);

    for(var result in results){
      var m = model.modelFactory() as T;
      await _resultToModel(result, m);
      list.add(m);
    }

    return list;
  }

  Future _resultToModel(Map<String, dynamic> data, OrmModel model) async {


    data.forEach((key, value){

      _debug(("resulttomodel: $key, $value"));

      if(key == "id") {
        model.id = value as int;
        return;
      }

      var column = AppGet.firstWhere<OrmColumn>(model.columns, (it) => it.name == key);

      if(column != null){

        var dbValue = value;

        switch(column.type){
          case OrmColumnType.Date:
            if(dbValue != null && "$dbValue".trim().length > 0)
              dbValue = dateFormat.parse(dbValue);
            else
              dbValue = null;
            break;
          case OrmColumnType.DateTime:
            if(dbValue != null && "$dbValue".trim().length > 0)
              dbValue = datetimeFormat.parse(dbValue);
            else
              dbValue = null;
            break;
          case OrmColumnType.Enum:
            if(dbValue != null && "$dbValue".trim().length > 0)
              dbValue = AppGet.firstWhere(column.enumValues, (p) => p.toString().split(".")[1].toUpperCase() == dbValue.toString().toUpperCase());
            else
              dbValue = null;
            break;
          case OrmColumnType.Bool:
            if(dbValue != null && "$dbValue".trim().length > 0)
              dbValue = int.parse("$dbValue") > 0;
            else
              dbValue = false;
            break;
          case OrmColumnType.Relation:
            if(dbValue != null && "$dbValue".trim().length > 0) {
              var md = model.relationFactory(column.name)!;
              md.id = int.parse("$dbValue");
              dbValue = md;
            }else{
              dbValue = null;
            }
            break;
          case OrmColumnType.List:
            _debug("ignore list property $key to load model");
            break;
          default:
            _debug("user default db value to property $key = $dbValue on load model");
        }

        model.setColumnValue(column.name, dbValue);

      }else{
        _debug("column $key not found to model ${model.tableName}");
      }

    });
  }

  Future executeNativeResultTransformer(OrmModel model, String query, [List? args]) async{
    var results = await executeQuery(query, args: args);
    if(results.isNotEmpty) {
      _debug("native result ${results[0]}");
      await _resultToModel(results[0], model);
    }
  }


  Map createInsertQuery(OrmModel model){

    var args = [];
    var names = "";
    var values = "";

    for(var it in model.columns) {

      if (it.primaryKey || it.type == OrmColumnType.List)
        continue;

      names += "${it.name},";
      values += "?,";


      if (it.type == OrmColumnType.DateTime) {
        var val = model.getColumnValue(it.name);
        if (val != null)
          args.add(datetimeFormat.format(val as DateTime));
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Date) {
        var val = model.getColumnValue(it.name);
        if (val != null)
          args.add(dateFormat.format(val as DateTime));
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Bool) {
        var val = model.getColumnValue(it.name) as bool;
        args.add(val);
      } else if (it.type == OrmColumnType.Enum) {
        var val = model.getColumnValue(it.name);
        if(val != null)
          args.add(val.toString().split(".")[1]);
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Relation) {
        var val = model.getColumnValue(it.name);
        if (val != null) {
          val = val as OrmModel;
          args.add(val.id);
        } else {
          args.add(null);
        }
      } else {
        args.add(model.getColumnValue(it.name));
      }
    }

    // remove last (,)
    names = names.substring(0, names.length-1);
    values = values.substring(0, values.length-1);

    return {
      "query": "insert into " + model.tableName + " (" + names + ") values (" + values + ")",
      "args": args
    };
  }

  Map createUpdateQuery(OrmModel model){

    var args = [];
    var names = "";

    for(var it in model.columns) {

      if (it.primaryKey || it.type == OrmColumnType.List)
        continue;


      names +=  " ${it.name} = ?,";

      if (it.type == OrmColumnType.DateTime) {
        var val = model.getColumnValue(it.name);
        if (val != null)
          args.add(datetimeFormat.format(val as DateTime));
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Date) {
        var val = model.getColumnValue(it.name);
        if (val != null)
          args.add(dateFormat.format(val as DateTime));
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Bool) {
        var val = model.getColumnValue(it.name) as bool;
        args.add(val);
      } else if (it.type == OrmColumnType.Enum) {
        var val = model.getColumnValue(it.name);
        if(val != null)
          args.add(val.toString().split(".")[1]);
        else
          args.add(null);
      } else if (it.type == OrmColumnType.Relation) {
        var val = model.getColumnValue(it.name);
        if (val != null) {
          val = val as OrmModel;
          args.add(val.id);
        } else {
          args.add(null);
        }
      } else {
        args.add(model.getColumnValue(it.name));
      }
    }

    args.add(model.id);

    // remove last (,)
    names = names.substring(0, names.length-1);

    return {
      "query": "update " + model.tableName + " set " + names + " where id = ?",
      "args": args
    };
  }

  Map createFilterQuery(OrmModel model, OrmFilter filter){

    var names = "";
    var cons = "";
    var sql = "";
    var args = [];

    if(filter.select) {
      for (var column in model.columns) {
        if (column.type == OrmColumnType.List)
          continue;
        names += "c.${column.name},";
      }

      names = names.substring(0, names.length - 1);

      sql = " select " + names + " from " + model.tableName + " c ";
    } else if(filter.delete) {
      sql = " delete from " + model.tableName;
    }else if(filter.count) {
      sql = " select count(id) from " + model.tableName;
    }

    if(filter.joins.isNotEmpty) {
      for (var join in filter.joins)
        sql += " $join ";
    }

    for(var criteria in filter.criterias) {

      if(criteria.native.isNotEmpty) {
        cons += criteria.native;

        if(criteria.value != null)
          args.add(criteria.value);
        else if(criteria.args.isNotEmpty && criteria.args.isNotEmpty)
          args.addAll(criteria.args);

      }else {

        var op = criteria.operation;
        var columnName = criteria.columnName;

        // how can be join column, verify if no gas dot
        if(columnName.indexOf(".") == -1)
          columnName = "c.$columnName ";

        cons += " $columnName";

        if(criteria.value != null){
          cons += " $op ? ";
          args.add(criteria.value);
        }

        cons += " and";

      }
    }


    cons = cons.substring(0, cons.length-3);
    sql += " where " + cons;

    if(filter.orders.isNotEmpty) {
      sql += " order by ";
      for (var order in filter.orders) {
        sql += "${order.sort} ${order.order}, ";
      }

      sql += sql.substring(0, sql.length-2);
    }

    if(filter.limit > 0){
      sql += " limit ? offset ?";
      args.add(filter.limit);
      args.add(filter.offset);
    }

    return {
      "query": sql,
      "args": args
    };
  }
}