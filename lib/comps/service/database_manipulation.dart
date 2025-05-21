import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert'; // Import for JSON decoding
import 'package:flutter/services.dart'; // Import for loading assets

// --- Join Specification Class ---
/// Represents a single JOIN clause in a SQL query.
class Join {
  final String table;
  final String on;
  final String type; // e.g., 'INNER', 'LEFT', 'CROSS'

  Join({
    required this.table,
    required this.on,
    this.type = 'INNER', // Default to INNER JOIN
  });
}

// --- Database Helper ---
// This class manages the database connection and creation.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get a location using getDatabasesPath
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'elexam.db'); // Your database name

    // Delete the database if it exists to start fresh for testing data loading
    // await deleteDatabase(path); // Uncomment this line to force recreation and data loading

    // Open the database
    return await openDatabase(
      path,
      version: 1, // Database version
      onCreate: _onCreate, // Function to create tables and populate
      onConfigure: _onConfigure, // Function to configure the database
    );
  }

  // Configure the database to enforce foreign key constraints
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create tables and populate with data from asset
  Future _onCreate(Database db, int version) async {
    // Create tables based on your schema
    // NOTE: The foreign key definition in 'typenamegrade' referencing 'typename(creatortype)'
    // seems unusual. It's more common to reference the primary key (id).
    // If your schema truly intends this, the data in your JSON must match this structure.
    // The code below assumes 'typenamegrade.typename' should reference 'typename.id'.
    // If your schema is correct as is, you might need to adjust the insertion logic
    // to find the 'typename.creatortype' value from the JSON for the foreign key.
    await db.execute('''
      CREATE TABLE chapter (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        grade INTEGER REFERENCES grade (id),
        subject INTEGER REFERENCES subject (id),
        name STRING,
        unit STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE creatortype (
        id INTEGER PRIMARY KEY UNIQUE,
        name STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE exam (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        name STRING,
        subject INTEGER REFERENCES subject (id),
        time INTEGER,
        code INTEGER UNIQUE ON CONFLICT ROLLBACK,
        grade STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE favorite (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        question INTEGER REFERENCES question (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE favoriteexam (
        id INTEGER PRIMARY KEY,
        examoff INTEGER REFERENCES exam (id),
        examon INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE grade (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        name STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE question (
        id INTEGER,
        exam INTEGER REFERENCES exam (id),
        ques TEXT,
        a TEXT,
        b TEXT,
        c TEXT,
        d TEXT,
        ans CHAR,
        explanation TEXT,
        subchapter INTEGER REFERENCES subchapter (id),
        chapter INTEGER REFERENCES chapter (id),
        image STRING,
        note TEXT,
        is_ai INTEGER,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE "result" (
        "id" INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        "exam" INTEGER REFERENCES "exam"("id"),
        "right" STRING,
        "wrong" STRING,
        "unanswered" STRING,
        "date" TEXT,
        "uploaded" INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE resultchapter (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        result INTEGER REFERENCES result (id),
        chapter INTEGER REFERENCES chapter (id),
        no_questions INT,
        "right" INT,
        wrong INT,
        unanswered INT,
        avg_time STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE resulttime (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        result INTEGER REFERENCES result (id),
        question INTEGER REFERENCES question (id),
        time STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE resultwrong (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        result INTEGER REFERENCES result (id),
        question INTEGER REFERENCES question (id),
        choosen STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE subchapter (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        chapter INTEGER REFERENCES chapter (id),
        name STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE subject (
        id INTEGER PRIMARY KEY, -- Removed AUTOINCREMENT
        name STRING
      )
    ''');
    await db.execute('''
      CREATE TABLE typename (
        creatortype INTEGER REFERENCES creatortype (id) ON DELETE CASCADE ON UPDATE CASCADE,
        name STRING,
        id INTEGER PRIMARY KEY UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE typenamegrade (
        typename INTEGER REFERENCES typename (id) ON DELETE CASCADE ON UPDATE CASCADE, -- Adjusted FK to reference typename(id)
        grade INTEGER REFERENCES grade (id),
        id INTEGER PRIMARY KEY UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE typenamegradesubject (
        typenamegrade INTEGER REFERENCES typenamegrade (id),
        subject INTEGER REFERENCES subject (id),
        id INTEGER PRIMARY KEY UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE typenamegradesubjectexam (
        typenamegradesubject INTEGER REFERENCES typenamegradesubject (id),
        exam INTEGER REFERENCES exam (id),
        id INTEGER PRIMARY KEY UNIQUE
      )
    ''');

    // --- Load and populate data from asset ---
    try {
      String jsonString = await rootBundle.loadString(
        'assets/Medicine COC 2018 from server.json',
      );
      Map<String, dynamic> data = json.decode(jsonString);
      await insertDataFromJson(db, data); // Use the new function
    } catch (e) {
      print('Error loading or parsing asset: $e');
      // Handle the error appropriately, e.g., show an error message to the user
    }
  }

  /// Inserts data into the database from a JSON structure.
  /// This function assumes the JSON structure is similar to the provided example.
  /// It handles nested objects and lists for insertion into related tables.
  Future<void> insertDataFromJson(
    Database db,
    Map<String, dynamic> data,
  ) async {
    // Process and insert data with careful null checks and foreign key alignment
    // Insert data into parent tables first to satisfy foreign key constraints

    // Assuming the JSON structure has keys matching your table names or a structure you can parse
    // You'll need to adjust this parsing logic based on the exact structure of your JSON file.

    // Insert CreatorType
    var typeNameGradeSubjectExamData = data['type_name_grade_subject_exam'];
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null) {
        var typeNameGradeData = typeNameGradeSubjectData['type_name_grade'];
        if (typeNameGradeData != null) {
          var typeNameData = typeNameGradeData['type_name'];
          if (typeNameData != null) {
            var creatorTypeData = typeNameData['creator_type'];
            if (creatorTypeData != null &&
                creatorTypeData['id'] != null &&
                creatorTypeData['name'] != null) {
              await db.insert('creatortype', {
                'id': creatorTypeData['id'],
                'name': creatorTypeData['name'],
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        }
      }
    }

    // Insert Grade
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null) {
        var typeNameGradeData = typeNameGradeSubjectData['type_name_grade'];
        if (typeNameGradeData != null) {
          var gradeData = typeNameGradeData['grade'];
          if (gradeData != null &&
              gradeData['id'] != null &&
              gradeData['name'] != null) {
            await db.insert('grade', {
              'id': gradeData['id'],
              'name': gradeData['name'],
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    }

    // Insert Subject
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null) {
        var subjectData = typeNameGradeSubjectData['subject'];
        if (subjectData != null &&
            subjectData['id'] != null &&
            subjectData['name'] != null) {
          await db.insert('subject', {
            'id': subjectData['id'],
            'name': subjectData['name'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    // Insert TypeName, referencing CreatorType (now that creatortype is inserted)
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null) {
        var typeNameGradeData = typeNameGradeSubjectData['type_name_grade'];
        if (typeNameGradeData != null) {
          // typeNameData is now declared here, accessible to the following block
          var typeNameData = typeNameGradeData['type_name'];
          if (typeNameData != null &&
              typeNameData['id'] != null &&
              typeNameData['name'] != null) {
            var creatorTypeId = typeNameData['creator_type']?['id'];
            await db.insert('typename', {
              'id': typeNameData['id'],
              'name': typeNameData['name'],
              'creatortype': creatorTypeId,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    }

    // Insert TypeNameGrade, referencing TypeName (id) and Grade (now that both are inserted)
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null) {
        var typeNameGradeData = typeNameGradeSubjectData['type_name_grade'];
        if (typeNameGradeData != null && typeNameGradeData['id'] != null) {
          var typenameIdForGrade = typeNameGradeData['type_name']?['id'];
          var gradeIdForTypeNameGrade = typeNameGradeData['grade']?['id'];

          if (typenameIdForGrade != null && gradeIdForTypeNameGrade != null) {
            await db.insert('typenamegrade', {
              'id': typeNameGradeData['id'],
              'typename': typenameIdForGrade,
              'grade': gradeIdForTypeNameGrade,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    }

    // Insert TypeNameGradeSubject, referencing TypeNameGrade and Subject (now that both are inserted)
    if (typeNameGradeSubjectExamData != null) {
      var typeNameGradeSubjectData =
          typeNameGradeSubjectExamData['type_name_grade_subject'];
      if (typeNameGradeSubjectData != null &&
          typeNameGradeSubjectData['id'] != null) {
        var typenamegradeIdForTGS =
            typeNameGradeSubjectData['type_name_grade']?['id'];
        var subjectIdForTGS = typeNameGradeSubjectData['subject']?['id'];
        if (typenamegradeIdForTGS != null && subjectIdForTGS != null) {
          await db.insert('typenamegradesubject', {
            'id': typeNameGradeSubjectData['id'],
            'typenamegrade': typenamegradeIdForTGS,
            'subject': subjectIdForTGS,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    // Insert Exam, referencing Subject (now that subject is inserted)
    // We'll use the 'code' from the JSON as the 'id' since AUTOINCREMENT is removed
    var examData = data['exam'];
    if (examData != null && examData['code'] != null) {
      var subjectIdForExam =
          examData['subject']; // Assuming subject is directly an ID here
      if (examData['name'] != null &&
          examData['time'] != null &&
          examData['grade'] != null &&
          subjectIdForExam != null) {
        await db.insert('exam', {
          'id': examData['code'], // Use code from JSON as the ID
          'name': examData['name'],
          'subject': subjectIdForExam,
          'time': examData['time'],
          'code': examData['code'], // Keep code as is
          'grade': examData['grade'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Insert TypeNameGradeSubjectExam, referencing TypeNameGradeSubject and Exam (now that both are inserted)
    if (typeNameGradeSubjectExamData != null &&
        typeNameGradeSubjectExamData['id'] != null &&
        examData != null &&
        examData['code'] != null) {
      var typenamegradesubjectIdForTGSE =
          typeNameGradeSubjectExamData['type_name_grade_subject']?['id'];
      if (typenamegradesubjectIdForTGSE != null) {
        await db.insert('typenamegradesubjectexam', {
          'id': typeNameGradeSubjectExamData['id'],
          'typenamegradesubject': typenamegradesubjectIdForTGSE,
          'exam': examData['code'], // Use code from JSON as the exam ID
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Insert Chapters and Subchapters, referencing Grade and Subject (for Chapter) and Chapter (for Subchapter)
    // This part needs to iterate through the questions to find chapter and subchapter data
    if (examData != null && examData.containsKey('questions')) {
      List<dynamic> questions = examData['questions'];
      // Get the subject ID from the exam data once before the loop
      var examSubjectId = examData['subject'];

      for (var questionData in questions) {
        // Insert related chapter data if it exists and is not already inserted
        if (questionData.containsKey('chapter') &&
            questionData['chapter'] != null) {
          var chapterData = questionData['chapter'];
          var gradeIdForChapter =
              chapterData['grade']; // Assuming grade ID is directly available
          // Use the examSubjectId for the chapter's subject
          var chapterSubjectId = examSubjectId;

          if (chapterData['id'] != null &&
              chapterData['name'] != null &&
              chapterData['unit'] != null &&
              gradeIdForChapter != null) {
            await db.insert('chapter', {
              'id': chapterData['id'],
              'grade': gradeIdForChapter,
              'subject':
                  chapterSubjectId, // Set chapter subject to exam subject
              'name': chapterData['name'],
              'unit': chapterData['unit'],
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }

        // Insert related subchapter data if it exists and is not already inserted
        if (questionData.containsKey('sub_chapter') &&
            questionData['sub_chapter'] != null) {
          var subchapterData = questionData['sub_chapter'];
          var chapterIdForSub =
              questionData['chapter']?['id']; // Link to chapter
          if (subchapterData['id'] != null &&
              subchapterData['name'] != null &&
              chapterIdForSub != null) {
            await db.insert('subchapter', {
              'id': subchapterData['id'],
              'chapter': chapterIdForSub,
              'name': subchapterData['name'],
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    }

    // Finally, insert Questions, referencing Exam, Subchapter, and Chapter
    if (examData != null &&
        examData.containsKey('questions') &&
        examData['code'] != null) {
      List<dynamic> questions = examData['questions'];
      for (var questionData in questions) {
        var subchapterId = questionData['sub_chapter']?['id'];
        var chapterId = questionData['chapter']?['id'];

        if (questionData['id'] != null &&
            questionData['ques'] != null &&
            questionData['ans'] != null) {
          await db.insert('question', {
            'id': questionData['id'],
            'exam': examData['code'], // Use code from JSON as the exam ID
            'ques': questionData['ques'],
            'a': questionData['choice_a'],
            'b': questionData['choice_b'],
            'c': questionData['choice_c'],
            'd': questionData['choice_d'],
            'ans': questionData['ans'],
            'explanation': questionData['explanation'],
            'subchapter': subchapterId,
            'chapter': chapterId,
            'image': questionData['image'],
            'note': questionData['note'],
            'is_ai':
                questionData['is_ai'] == true
                    ? 1
                    : 0, // Convert boolean to integer
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        } else {
          print(
            'Skipping question due to missing required fields: ${questionData['id']}',
          );
        }
      }
    }

    // Add similar logic here to insert data into other tables
    // based on the structure of your JSON file.
    // Remember to handle foreign key relationships.
  }

  /// Performs a joined query across multiple tables.
  /// Returns a list of maps representing the query results.
  /// [selectColumns]: List of columns to select (e.g., ['table1.col1', 'table2.col2']).
  /// [fromTable]: The starting table for the query.
  /// [joins]: A list of [Join] objects, each specifying a JOIN.
  /// [where]: The WHERE clause (optional).
  /// [whereArgs]: The arguments for the WHERE clause (optional).
  /// [orderBy]: The ORDER BY clause (optional).
  /// [limit]: The LIMIT clause (optional).
  /// [offset]: The OFFSET clause (optional).
  /// [distinct]: Whether to return distinct rows (optional).
  Future<List<Map<String, dynamic>>> performJoinedQuery({
    required List<String> selectColumns,
    required String fromTable,
    required List<Join> joins,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    bool distinct = false, // Added distinct parameter
  }) async {
    final db = await database;
    StringBuffer queryBuffer = StringBuffer(
      'SELECT ${distinct ? 'DISTINCT ' : ''}${selectColumns.join(', ')} FROM $fromTable',
    );

    for (var join in joins) {
      queryBuffer.write(' ${join.type} JOIN ${join.table} ON ${join.on}');
    }

    if (where != null) {
      queryBuffer.write(' WHERE $where');
    }
    if (orderBy != null) {
      queryBuffer.write(' ORDER BY $orderBy');
    }
    if (limit != null) {
      queryBuffer.write(' LIMIT $limit');
    }
    if (offset != null) {
      queryBuffer.write(' OFFSET $offset');
    }

    return await db.rawQuery(queryBuffer.toString(), whereArgs);
  }
}

// --- Base Model Class ---
// Provides common database operations.
abstract class DatabaseModel<T> {
  String get tableName;
  Map<String, dynamic> toMap();
  T fromMap(Map<String, dynamic> map);

  Future<Database> get _db async {
    return await DatabaseHelper().database;
  }

  // Create/Insert
  Future<int> save() async {
    final db = await _db;
    // If the model has an ID (assuming 'id' is the primary key name),
    // it tries to update; otherwise, it inserts.
    // This is a simplified approach, you might need to adjust based on your ID handling.
    if (toMap().containsKey('id') && toMap()['id'] != null) {
      // Assuming 'id' is the primary key name
      int id = toMap()['id'];
      await db.update(tableName, toMap(), where: 'id = ?', whereArgs: [id]);
      return id; // Return the updated ID
    } else {
      return await db.insert(tableName, toMap());
    }
  }

  // Read/Get by ID
  Future<T?> getById(int id) async {
    final db = await _db;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  // Read/Get all
  Future<List<T>> getAll() async {
    final db = await _db;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return fromMap(maps[i]);
    });
  }

  // Update (explicit update method)
  Future<int> update() async {
    final db = await _db;
    // Assuming 'id' is the primary key name and exists in the map
    if (toMap().containsKey('id') && toMap()['id'] != null) {
      int id = toMap()['id'];
      return await db.update(
        tableName,
        toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      throw Exception("Cannot update model without an ID.");
    }
  }

  // Delete
  Future<int> delete() async {
    final db = await _db;
    // Assuming 'id' is the primary key name and exists in the map
    if (toMap().containsKey('id') && toMap()['id'] != null) {
      int id = toMap()['id'];
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    } else {
      throw Exception("Cannot delete model without an ID.");
    }
  }

  // Custom query example (you can add more as needed)
  Future<List<T>> query({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return fromMap(maps[i]);
    });
  }
}

// --- Model Classes for Each Table ---

class Chapter extends DatabaseModel<Chapter> {
  final int? id;
  final int? grade; // Foreign key to Grade
  final int? subject; // Foreign key to Subject
  final String? name;
  final String? unit;

  Chapter({this.id, this.grade, this.subject, this.name, this.unit});

  @override
  String get tableName => 'chapter';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'name': name,
      'unit': unit,
    };
  }

  @override
  Chapter fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'],
      grade: map['grade'],
      subject: map['subject'],
      name: map['name'],
      unit: map['unit'],
    );
  }

  // Relationship methods

  /// Fetches the related Grade object.
  Future<Grade?> getGrade() async {
    if (grade == null) return null;
    return await Grade().getById(grade!);
  }

  /// Fetches the related Subject object.
  Future<Subject?> getSubject() async {
    if (subject == null) return null;
    return await Subject().getById(subject!);
  }

  /// Fetches all related Subchapter objects.
  Future<List<Subchapter>> getSubchapters() async {
    if (id == null) return [];
    return await Subchapter().query(where: 'chapter = ?', whereArgs: [id]);
  }

  /// Fetches all related Question objects.
  Future<List<Question>> getQuestions() async {
    if (id == null) return [];
    return await Question().query(where: 'chapter = ?', whereArgs: [id]);
  }

  /// Fetches all related ResultChapter objects.
  Future<List<ResultChapter>> getResultChapters() async {
    if (id == null) return [];
    return await ResultChapter().query(where: 'chapter = ?', whereArgs: [id]);
  }

  /// Fetches a distinct list of Chapter units associated with a specific
  /// TypeNameGradeSubjectExam ID by traversing relationships.
  static Future<List<String>> getDistinctChapterUnitsByTypeNameGradeSubject(
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the join path from chapter to typenamegradesubjectexam
    final joins = [
      Join(table: 'question', on: 'chapter.id = question.chapter'),
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (only the distinct unit)
    final selectColumns = ['DISTINCT chapter.unit'];

    // Define the where clause to filter by typenamegradesubject.id
    final whereClause = 'typenamegradesubject.id = ?';
    final whereArgs = [typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'chapter',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Extract the unit strings from the results
    return results.map((row) => row['unit'] as String).toList();
  }

  /// Fetches a distinct list of Chapter names associated with a specific
  /// TypeNameGradeSubjectExam ID by traversing relationships.
  static Future<List<String>> getDistinctChapterNamesByTypeNameGradeSubject(
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the join path from chapter to typenamegradesubjectexam
    final joins = [
      Join(table: 'question', on: 'chapter.id = question.chapter'),
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (only the distinct name)
    final selectColumns = ['DISTINCT chapter.name'];

    // Define the where clause to filter by typenamegradesubject.id
    final whereClause = 'typenamegradesubject.id = ?';
    final whereArgs = [typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'chapter',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Extract the name strings from the results
    return results.map((row) => row['name'] as String).toList();
  }
}

class CreatorType extends DatabaseModel<CreatorType> {
  final int? id;
  final String? name;

  CreatorType({this.id, this.name});

  @override
  String get tableName => 'creatortype';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  @override
  CreatorType fromMap(Map<String, dynamic> map) {
    return CreatorType(id: map['id'], name: map['name']);
  }

  // Relationship methods

  /// Fetches all related TypeName objects.
  Future<List<TypeName>> getTypeNames() async {
    if (id == null) return [];
    return await TypeName().query(where: 'creatortype = ?', whereArgs: [id]);
  }
}

class Exam extends DatabaseModel<Exam> {
  final int? id;
  final String? name;
  final int? subject; // Foreign key to Subject
  final int? time;
  final int? code; // Changed to int?
  final String? grade;

  Exam({this.id, this.name, this.subject, this.time, this.code, this.grade});

  @override
  String get tableName => 'exam';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'time': time,
      'code': code, // Stays as int
      'grade': grade,
    };
  }

  @override
  Exam fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      name: map['name'],
      subject: map['subject'],
      time: map['time'],
      code: map['code'], // Reads as int
      grade: map['grade'].toString(),
    );
  }

  // Relationship methods

  /// Fetches the related Subject object.
  Future<Subject?> getSubject() async {
    if (subject == null) return null;
    return await Subject().getById(subject!);
  }

  /// Fetches all related Question objects.
  Future<List<Question>> getQuestions() async {
    if (id == null) return [];
    return await Question().query(where: 'exam = ?', whereArgs: [id]);
  }

  static Future<bool> existsInLocalDb(int examId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.query(
        'exam',
        columns: ['COUNT(*)'],
        where: 'id = ?',
        whereArgs: [examId],
      ),
    );
    return (count ?? 0) > 0;
  }

  /// Fetches all related FavoriteExam objects.
  Future<List<FavoriteExam>> getFavoriteExams() async {
    if (id == null) return [];
    return await FavoriteExam().query(where: 'examoff = ?', whereArgs: [id]);
  }

  /// Fetches all related Result objects.
  Future<List<Result>> getResults() async {
    if (id == null) return [];
    return await Result().query(where: 'exam = ?', whereArgs: [id]);
  }

  /// Fetches all related TypeNameGradeSubjectExam objects.
  Future<List<TypeNameGradeSubjectExam>> getTypeNameGradeSubjectExams() async {
    if (id == null) return [];
    return await TypeNameGradeSubjectExam().query(
      where: 'exam = ?',
      whereArgs: [id],
    );
  }

  // --- Example using the dynamic performJoinedQuery with Join objects ---

  /// Fetches all Exams associated with a specific CreatorType ID
  /// using the dynamic performJoinedQuery method and Join objects.
  static Future<List<Exam>> getExamsByCreatorTypeDynamic(
    int creatorTypeId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the join path from exam to creatortype using Join objects
    final joins = [
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
      Join(
        table: 'typenamegrade',
        on: 'typenamegradesubject.typenamegrade = typenamegrade.id',
      ),
      Join(
        table: 'typename',
        on: 'typenamegrade.typename = typename.id',
      ), // Assuming typenamegrade.typename references typename.id
      Join(table: 'creatortype', on: 'typename.creatortype = creatortype.id'),
    ];

    // Perform the joined query
    List<Map<String, dynamic>> maps = await dbHelper.performJoinedQuery(
      selectColumns: ['exam.*'], // Select all columns from the exam table
      fromTable: 'exam',
      joins: joins,
      where: 'creatortype.id = ?',
      whereArgs: [creatorTypeId],
      distinct: true, // Ensure unique exams
    );

    // Convert the results back to a list of Exam objects
    return List.generate(maps.length, (i) {
      return Exam().fromMap(maps[i]);
    });
  }

  /// Fetches a list of Exam objects associated with a specific
  /// TypeNameGradeSubject ID by traversing relationships.
  static Future<List<Exam>> getExamsByTypeNameGradeSubject(
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the join path from exam to typenamegradesubject
    final joins = [
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (all columns from the exam table)
    final selectColumns = ['exam.*'];

    // Define the where clause to filter by typenamegradesubject.id
    final whereClause = 'typenamegradesubject.id = ?';
    final whereArgs = [typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'exam',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
      distinct: true, // Use distinct to ensure unique exams
    );

    // Convert the results back to a list of Exam objects
    return List.generate(results.length, (i) {
      return Exam().fromMap(results[i]);
    });
  }
}

class Favorite extends DatabaseModel<Favorite> {
  final int? id;
  final int? question; // Foreign key to Question

  Favorite({this.id, this.question});

  @override
  String get tableName => 'favorite';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'question': question};
  }

  @override
  Favorite fromMap(Map<String, dynamic> map) {
    return Favorite(id: map['id'], question: map['question']);
  }

  // Relationship methods

  /// Fetches the related Question object.
  Future<Question?> getQuestion() async {
    if (question == null) return null;
    return await Question().getById(question!);
  }
}

class FavoriteExam extends DatabaseModel<FavoriteExam> {
  final int? id;
  final int? examoff; // Foreign key to Exam
  final int? examon;

  FavoriteExam({this.id, this.examoff, this.examon});

  @override
  String get tableName => 'favoriteexam';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'examoff': examoff, 'examon': examon};
  }

  @override
  FavoriteExam fromMap(Map<String, dynamic> map) {
    return FavoriteExam(
      id: map['id'],
      examoff: map['examoff'],
      examon: map['examon'],
    );
  }

  // Relationship methods

  /// Fetches the related Exam object.
  Future<Exam?> getExam() async {
    if (examoff == null) return null;
    return await Exam().getById(examoff!);
  }
}

class Grade extends DatabaseModel<Grade> {
  final int? id;
  final String? name;

  Grade({this.id, this.name});

  @override
  String get tableName => 'grade';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  @override
  Grade fromMap(Map<String, dynamic> map) {
    return Grade(id: map['id'], name: map['name']);
  }

  // Relationship methods

  /// Fetches all related Chapter objects.
  Future<List<Chapter>> getChapters() async {
    if (id == null) return [];
    return await Chapter().query(where: 'grade = ?', whereArgs: [id]);
  }

  /// Fetches all related TypeNameGrade objects.
  Future<List<TypeNameGrade>> getTypeNameGrades() async {
    if (id == null) return [];
    return await TypeNameGrade().query(where: 'grade = ?', whereArgs: [id]);
  }
}

class Question extends DatabaseModel<Question> {
  final int? id;
  final int? exam; // Foreign key to Exam
  final String? ques;
  final String? a;
  final String? b;
  final String? c;
  final String? d;
  final String? ans;
  final String? explanation;
  final int? subchapter; // Foreign key to Subchapter
  final int? chapter; // Foreign key to Chapter
  final String? image;
  final String? note;
  final int? is_ai;

  Question({
    this.id,
    this.exam,
    this.ques,
    this.a,
    this.b,
    this.c,
    this.d,
    this.ans,
    this.explanation,
    this.subchapter,
    this.chapter,
    this.image,
    this.note,
    this.is_ai,
  });

  @override
  String get tableName => 'question';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam': exam,
      'ques': ques,
      'a': a,
      'b': b,
      'c': c,
      'd': d,
      'ans': ans,
      'explanation': explanation,
      'subchapter': subchapter,
      'chapter': chapter,
      'image': image,
      'note': note,
      'is_ai': is_ai,
    };
  }

  @override
  Question fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      exam: map['exam'],
      ques: map['ques'],
      a: map['a'],
      b: map['b'],
      c: map['c'],
      d: map['d'],
      ans: map['ans'],
      explanation: map['explanation'],
      subchapter: map['subchapter'],
      chapter: map['chapter'],
      image: map['image'],
      note: map['note'],
      is_ai: map['is_ai'],
    );
  }

  // Relationship methods

  /// Fetches the related Exam object.
  Future<Exam?> getExam() async {
    if (exam == null) return null;
    return await Exam().getById(exam!);
  }

  /// Fetches the related Subchapter object.
  Future<Subchapter?> getSubchapter() async {
    if (subchapter == null) return null;
    return await Subchapter().getById(subchapter!);
  }

  /// Fetches the related Chapter object.
  Future<Chapter?> getChapter() async {
    if (chapter == null) return null;
    return await Chapter().getById(chapter!);
  }

  /// Fetches all related Favorite objects.
  Future<List<Favorite>> getFavorites() async {
    if (id == null) return [];
    return await Favorite().query(where: 'question = ?', whereArgs: [id]);
  }

  /// Fetches all related ResultTime objects.
  Future<List<ResultTime>> getResultTimes() async {
    if (id == null) return [];
    return await ResultTime().query(where: 'result = ?', whereArgs: [id]);
  }

  /// Fetches all related ResultWrong objects.
  Future<List<ResultWrong>> getResultWrongs() async {
    if (id == null) return [];
    return await ResultWrong().query(where: 'result = ?', whereArgs: [id]);
  }

  /// Fetches a list of Question objects associated with a specific
  /// Chapter unit and TypeNameGradeSubject ID by joining with the
  /// Chapter, Exam, and TypeNameGradeSubjectExam tables.
  static Future<List<Question>>
  getQuestionsByChapterUnitAndTypeNameGradeSubject(
    String unit,
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the joins
    final joins = [
      Join(table: 'chapter', on: 'question.chapter = chapter.id'),
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (all columns from the question table)
    final selectColumns = ['question.*'];

    // Define the where clause to filter by chapter.unit and typenamegradesubject.id
    final whereClause = 'chapter.unit = ? AND typenamegradesubject.id = ?';
    final whereArgs = [unit, typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'question',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
      distinct: true, // Use distinct to ensure unique questions if needed
    );

    // Convert the results back to a list of Question objects
    return List.generate(results.length, (i) {
      return Question().fromMap(results[i]);
    });
  }

  /// Fetches a list of Question objects associated with a specific
  /// Chapter name and TypeNameGradeSubject ID by joining with the
  /// Chapter, Exam, and TypeNameGradeSubjectExam tables.
  static Future<List<Question>>
  getQuestionsByChapterNameAndTypeNameGradeSubject(
    String chapterName,
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the joins
    final joins = [
      Join(table: 'chapter', on: 'question.chapter = chapter.id'),
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (all columns from the question table)
    final selectColumns = ['question.*'];

    // Define the where clause to filter by chapter.name and typenamegradesubject.id
    final whereClause = 'chapter.name = ? AND typenamegradesubject.id = ?';
    final whereArgs = [chapterName, typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'question',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
      distinct: true, // Use distinct to ensure unique questions if needed
    );

    // Convert the results back to a list of Question objects
    return List.generate(results.length, (i) {
      return Question().fromMap(results[i]);
    });
  }

  /// Fetches a list of Question objects associated with a specific
  /// Subchapter name and TypeNameGradeSubject ID by joining with the
  /// Subchapter, Chapter, Exam, and TypeNameGradeSubjectExam tables.
  static Future<List<Question>>
  getQuestionsBySubchapterNameAndTypeNameGradeSubject(
    String subchapterName,
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the joins
    final joins = [
      Join(table: 'subchapter', on: 'question.subchapter = subchapter.id'),
      Join(
        table: 'chapter',
        on: 'question.chapter = chapter.id',
      ), // Include chapter join as subchapter is linked to it
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (all columns from the question table)
    final selectColumns = ['question.*'];

    // Define the where clause to filter by subchapter.name and typenamegradesubject.id
    final whereClause = 'subchapter.name = ? AND typenamegradesubject.id = ?';
    final whereArgs = [subchapterName, typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'question',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
      distinct: true, // Use distinct to ensure unique questions if needed
    );

    // Convert the results back to a list of Question objects
    return List.generate(results.length, (i) {
      return Question().fromMap(results[i]);
    });
  }
}

class Result extends DatabaseModel<Result> {
  final int? id;
  final int? exam; // Foreign key to Exam
  final String? right;
  final String? wrong;
  final String? unanswered;
  final String? date;
  final int? uploaded;

  Result({
    this.id,
    this.exam,
    this.right,
    this.wrong,
    this.unanswered,
    this.date,
    this.uploaded,
  });

  @override
  String get tableName => 'result';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam': exam,
      'right': right,
      'wrong': wrong,
      'unanswered': unanswered,
      'date': date,
      'uploaded': uploaded,
    };
  }

  @override
  Result fromMap(Map<String, dynamic> map) {
    return Result(
      id: map['id'],
      exam: map['exam'],
      right: map['right'],
      wrong: map['wrong'],
      unanswered: map['unanswered'],
      date: map['date'],
      uploaded: map['uploaded'],
    );
  }

  // Relationship methods

  /// Fetches the related Exam object.
  Future<Exam?> getExam() async {
    if (exam == null) return null;
    return await Exam().getById(exam!);
  }

  /// Fetches all related ResultChapter objects.
  Future<List<ResultChapter>> getResultChapters() async {
    if (id == null) return [];
    return await ResultChapter().query(where: 'chapter = ?', whereArgs: [id]);
  }

  /// Fetches all related ResultTime objects.
  Future<List<ResultTime>> getResultTimes() async {
    if (id == null) return [];
    return await ResultTime().query(where: 'result = ?', whereArgs: [id]);
  }

  /// Fetches all related ResultWrong objects.
  Future<List<ResultWrong>> getResultWrongs() async {
    if (id == null) return [];
    return await ResultWrong().query(where: 'result = ?', whereArgs: [id]);
  }
}

class ResultChapter extends DatabaseModel<ResultChapter> {
  final int? id;
  final int? result; // Foreign key to Result
  final int? chapter; // Foreign key to Chapter
  final int? no_questions;
  final int? right;
  final int? wrong;
  final int? unanswered;
  final String? avg_time;

  ResultChapter({
    this.id,
    this.result,
    this.chapter,
    this.no_questions,
    this.right,
    this.wrong,
    this.unanswered,
    this.avg_time,
  });

  @override
  String get tableName => 'resultchapter';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result': result,
      'chapter': chapter,
      'no_questions': no_questions,
      'right': right,
      'wrong': wrong,
      'unanswered': unanswered,
      'avg_time': avg_time,
    };
  }

  @override
  ResultChapter fromMap(Map<String, dynamic> map) {
    return ResultChapter(
      id: map['id'],
      result: map['result'],
      chapter: map['chapter'],
      no_questions: map['no_questions'],
      right: map['right'],
      wrong: map['wrong'],
      unanswered: map['unanswered'],
      avg_time: map['avg_time'],
    );
  }

  // Relationship methods

  /// Fetches the related Result object.
  Future<Result?> getResult() async {
    if (result == null) return null;
    return await Result().getById(result!);
  }

  /// Fetches the related Chapter object.
  Future<Chapter?> getChapter() async {
    if (chapter == null) return null;
    return await Chapter().getById(chapter!);
  }
}

class ResultTime extends DatabaseModel<ResultTime> {
  final int? id;
  final int? result; // Foreign key to Result
  final int? question; // Foreign key to Question
  final String? time;

  ResultTime({this.id, this.result, this.question, this.time});

  @override
  String get tableName => 'resulttime';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'result': result, 'question': question, 'time': time};
  }

  @override
  ResultTime fromMap(Map<String, dynamic> map) {
    return ResultTime(
      id: map['id'],
      result: map['result'],
      question: map['question'],
      time: map['time'],
    );
  }

  // Relationship methods

  /// Fetches the related Result object.
  Future<Result?> getResult() async {
    if (result == null) return null;
    return await Result().getById(result!);
  }

  /// Fetches the related Question object.
  Future<Question?> getQuestion() async {
    if (question == null) return null;
    return await Question().getById(question!);
  }
}

class ResultWrong extends DatabaseModel<ResultWrong> {
  final int? id;
  final int? result; // Foreign key to Result
  final int? question; // Foreign key to Question
  final String? choosen;

  ResultWrong({this.id, this.result, this.question, this.choosen});

  @override
  String get tableName => 'resultwrong';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result': result,
      'question': question,
      'choosen': choosen,
    };
  }

  @override
  ResultWrong fromMap(Map<String, dynamic> map) {
    return ResultWrong(
      id: map['id'],
      result: map['result'],
      question: map['question'],
      choosen: map['choosen'],
    );
  }

  // Relationship methods

  /// Fetches the related Result object.
  Future<Result?> getResult() async {
    if (result == null) return null;
    return await Result().getById(result!);
  }

  /// Fetches the related Question object.
  Future<Question?> getQuestion() async {
    if (question == null) return null;
    return await Question().getById(question!);
  }
}

class Subchapter extends DatabaseModel<Subchapter> {
  final int? id;
  final int? chapter; // Foreign key to Chapter
  final String? name;

  Subchapter({this.id, this.chapter, this.name});

  @override
  String get tableName => 'subchapter';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'chapter': chapter, 'name': name};
  }

  @override
  Subchapter fromMap(Map<String, dynamic> map) {
    return Subchapter(
      id: map['id'],
      chapter: map['chapter'],
      name: map['name'],
    );
  }

  // Relationship methods

  /// Fetches the related Chapter object.
  Future<Chapter?> getChapter() async {
    if (chapter == null) return null;
    return await Chapter().getById(chapter!);
  }

  /// Fetches all related Question objects.
  Future<List<Question>> getQuestions() async {
    if (id == null) return [];
    return await Question().query(where: 'subchapter = ?', whereArgs: [id]);
  }

  /// Fetches a distinct list of Subchapter names associated with a specific
  /// TypeNameGradeSubjectExam ID by traversing relationships.
  static Future<List<String>> getDistinctSubchapterNamesByTypeNameGradeSubject(
    int typenameGradeSubjectId,
  ) async {
    final dbHelper = DatabaseHelper();

    // Define the join path from subchapter to typenamegradesubject
    final joins = [
      Join(table: 'chapter', on: 'subchapter.chapter = chapter.id'),
      Join(
        table: 'question',
        on: 'chapter.id = question.chapter',
      ), // Assuming questions link to chapters
      Join(table: 'exam', on: 'question.exam = exam.id'),
      Join(
        table: 'typenamegradesubjectexam',
        on: 'exam.id = typenamegradesubjectexam.exam',
      ),
      Join(
        table: 'typenamegradesubject',
        on:
            'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
      ),
    ];

    // Define the columns to select (only the distinct name)
    final selectColumns = ['DISTINCT subchapter.name'];

    // Define the where clause to filter by typenamegradesubject.id
    final whereClause = 'typenamegradesubject.id = ?';
    final whereArgs = [typenameGradeSubjectId];

    // Perform the joined query
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'subchapter',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Extract the name strings from the results
    return results.map((row) => row['name'] as String).toList();
  }
}

class Subject extends DatabaseModel<Subject> {
  final int? id;
  final String? name;

  Subject({this.id, this.name});

  @override
  String get tableName => 'subject';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  @override
  Subject fromMap(Map<String, dynamic> map) {
    return Subject(id: map['id'], name: map['name']);
  }

  // Relationship methods

  /// Fetches all related Chapter objects.
  Future<List<Chapter>> getChapters() async {
    if (id == null) return [];
    return await Chapter().query(where: 'subject = ?', whereArgs: [id]);
  }

  /// Fetches all related Exam objects.
  Future<List<Exam>> getExams() async {
    if (id == null) return [];
    return await Exam().query(where: 'subject = ?', whereArgs: [id]);
  }

  /// Fetches all related TypeNameGradeSubject objects.
  Future<List<TypeNameGradeSubject>> getTypeNameGradeSubjects() async {
    if (id == null) return [];
    return await TypeNameGradeSubject().query(
      where: 'subject = ?',
      whereArgs: [id],
    );
  }
}

class TypeName extends DatabaseModel<TypeName> {
  final int? id;
  final int? creatortype; // Foreign key to CreatorType
  final String? name;

  TypeName({this.id, this.creatortype, this.name});

  @override
  String get tableName => 'typename';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'creatortype': creatortype, 'name': name};
  }

  @override
  TypeName fromMap(Map<String, dynamic> map) {
    return TypeName(
      id: map['id'],
      creatortype: map['creatortype'],
      name: map['name'],
    );
  }

  // Relationship methods

  /// Fetches the related CreatorType object.
  Future<CreatorType?> getCreatorType() async {
    if (creatortype == null) return null;
    return await CreatorType().getById(creatortype!);
  }

  /// Fetches all related TypeNameGrade objects.
  Future<List<TypeNameGrade>> getTypeNameGrades() async {
    if (id == null) return [];
    // Note: The foreign key in typenamegrade references typename(creatortype),
    // so we query typenamegrade where typenamegrade.typename matches this typename's id.
    return await TypeNameGrade().query(where: 'typename = ?', whereArgs: [id]);
  }
}

class TypeNameGrade extends DatabaseModel<TypeNameGrade> {
  final int? id;
  final int? typename; // Foreign key to TypeName (via creatortype)
  final int? grade; // Foreign key to Grade

  TypeNameGrade({this.id, this.typename, this.grade});

  @override
  String get tableName => 'typenamegrade';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'typename': typename, 'grade': grade};
  }

  @override
  TypeNameGrade fromMap(Map<String, dynamic> map) {
    return TypeNameGrade(
      id: map['id'],
      typename: map['typename'],
      grade: map['grade'],
    );
  }

  // Relationship methods

  /// Fetches the related TypeName object.
  Future<TypeName?> getTypeName() async {
    if (typename == null) return null;
    // Note: The foreign key in typenamegrade references typename(creatortype),
    // so we need to find the TypeName where creatortype matches this typename ID.
    // This is a bit unusual, assuming typename in typenamegrade refers to the id in typename.
    List<TypeName> typeNames = await TypeName().query(
      where: 'id = ?',
      whereArgs: [typename],
    );
    return typeNames.isNotEmpty ? typeNames.first : null;
  }

  /// Fetches the related Grade object.
  Future<Grade?> getGrade() async {
    if (grade == null) return null;
    return await Grade().getById(grade!);
  }

  /// Fetches all related TypeNameGradeSubject objects.
  Future<List<TypeNameGradeSubject>> getTypeNameGradeSubjects() async {
    if (id == null) return [];
    return await TypeNameGradeSubject().query(
      where: 'typenamegrade = ?',
      whereArgs: [id],
    );
  }
}

class TypeNameGradeSubject extends DatabaseModel<TypeNameGradeSubject> {
  final int? id;
  final int? typenamegrade; // Foreign key to TypeNameGrade
  final int? subject; // Foreign key to Subject

  TypeNameGradeSubject({this.id, this.typenamegrade, this.subject});

  @override
  String get tableName => 'typenamegradesubject';

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'typenamegrade': typenamegrade, 'subject': subject};
  }

  @override
  TypeNameGradeSubject fromMap(Map<String, dynamic> map) {
    return TypeNameGradeSubject(
      id: map['id'],
      typenamegrade: map['typenamegrade'],
      subject: map['subject'],
    );
  }

  // Relationship methods

  /// Fetches the related TypeNameGrade object.
  Future<TypeNameGrade?> getTypeNameGrade() async {
    if (typenamegrade == null) return null;
    return await TypeNameGrade().getById(typenamegrade!);
  }

  /// Fetches the related Subject object.
  Future<Subject?> getSubject() async {
    if (subject == null) return null;
    return await Subject().getById(subject!);
  }

  /// Fetches all related TypeNameGradeSubjectExam objects.
  Future<List<TypeNameGradeSubjectExam>> getTypeNameGradeSubjectExams() async {
    if (id == null) return [];
    return await TypeNameGradeSubjectExam().query(
      where: 'typenamegradesubject = ?',
      whereArgs: [id],
    );
  }
}

class TypeNameGradeSubjectExam extends DatabaseModel<TypeNameGradeSubjectExam> {
  final int? id;
  final int? typenamegradesubject; // Foreign key to TypeNameGradeSubject
  final int? exam; // Foreign key to Exam

  TypeNameGradeSubjectExam({this.id, this.typenamegradesubject, this.exam});

  @override
  String get tableName => 'typenamegradesubjectexam';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'typenamegradesubject': typenamegradesubject,
      'exam': exam,
    };
  }

  @override
  TypeNameGradeSubjectExam fromMap(Map<String, dynamic> map) {
    return TypeNameGradeSubjectExam(
      id: map['id'],
      typenamegradesubject: map['typenamegradesubject'],
      exam: map['exam'],
    );
  }

  // Relationship methods

  /// Fetches the related TypeNameGradeSubject object.
  Future<TypeNameGradeSubject?> getTypeNameGradeSubject() async {
    if (typenamegradesubject == null) return null;
    return await TypeNameGradeSubject().getById(typenamegradesubject!);
  }

  /// Fetches the related Exam object.
  Future<Exam?> getExam() async {
    if (exam == null) return null;
    return await Exam().getById(exam!);
  }
}
