// ==========================================
// 1. SCHEMA CONSTRAINTS
// ==========================================
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Program) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (f:Field) REQUIRE f.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (c:Course) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (t:Topic) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (o:Outcome) REQUIRE o.id IS UNIQUE;

// ==========================================
// 2. DATA IMPORT (NODES)
// ==========================================
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_programs.csv' AS row
MERGE (p:Program {id: coalesce(row.program_id, row.id)})
SET p.title = row.title,
    p.credit_points = row.credit_points,
    p.duration = row.duration,
    p.languages = row.languages;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_fields.csv' AS row
MERGE (f:Field {id: coalesce(row.field_id, row.study_field_id, row.id, row.name)})
SET f += row;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_courses.csv' AS row
MERGE (c:Course {id: coalesce(row.course_id, row.study_course_id, row.id, row.code)})
SET c += row;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_course_topics.csv' AS row
MERGE (t:Topic {id: coalesce(row.topic_id, row.course_topic_id, row.id, row.name)})
SET t += row;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_learning_outcomes.csv' AS row
MERGE (o:Outcome {id: coalesce(row.outcome_id, row.learning_outcome_id, row.id)})
SET o += row;

// ==========================================
// 3. DATA IMPORT (EDGES)
// ==========================================
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/program%2Bstudy_field.csv' AS row
MATCH (p:Program {id: coalesce(row.program_id, row.source, row.source_id)})
MATCH (f:Field {id: coalesce(row.field_id, row.study_field_id, row.target, row.target_id)})
MERGE (p)-[:HAS_FIELD]->(f);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/program%2Bcourse.csv' AS row
MATCH (p:Program {id: coalesce(row.program_id, row.source, row.source_id)})
MATCH (c:Course {id: coalesce(row.course_id, row.study_course_id, row.target, row.target_id, row.code)})
MERGE (p)-[:OFFERS_COURSE]->(c);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/course%2Btopic.csv' AS row
MATCH (c:Course {id: coalesce(row.course_id, row.study_course_id, row.source, row.source_id, row.code)})
MATCH (t:Topic {id: coalesce(row.topic_id, row.course_topic_id, row.target, row.target_id, row.name)})
MERGE (c)-[:COVERS_TOPIC]->(t);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/course%2Blearning_outcome.csv' AS row
MATCH (c:Course {id: coalesce(row.course_id, row.study_course_id, row.source, row.source_id, row.code)})
MATCH (o:Outcome {id: coalesce(row.outcome_id, row.learning_outcome_id, row.target, row.target_id)})
MERGE (c)-[:ACHIEVES_OUTCOME]->(o);

// ==========================================
// 4. ANALYTICAL QUERIES
// ==========================================

// Query 1: Multi-Hop Knowledge Graph Exploration
MATCH (p:Program)-[:OFFERS_COURSE]->(c:Course)-[r]->(target)
RETURN p, c, r, target
LIMIT 40;

// Query 2: Course Content Breadth (Degree Centrality on Topics)
MATCH (c:Course)-[:COVERS_TOPIC]->(t:Topic)
RETURN coalesce(c.title, c.name, c.id) AS CourseName, 
       count(t) AS TopicCount
ORDER BY TopicCount DESC
LIMIT 10;

// Query 3: Inter-Course Similarity via Shared Topics
MATCH (c1:Course)-[:COVERS_TOPIC]->(t:Topic)<-[:COVERS_TOPIC]-(c2:Course)
WHERE c1.id < c2.id
RETURN coalesce(t.title, t.name, t.id) AS SharedTopic, 
       coalesce(c1.title, c1.name, c1.id) AS CourseA, 
       coalesce(c2.title, c2.name, c2.id) AS CourseB
ORDER BY SharedTopic ASC
LIMIT 15;

// Query 4: Learning Outcome Density per Course
MATCH (c:Course)-[:ACHIEVES_OUTCOME]->(o:Outcome)
RETURN coalesce(c.title, c.name, c.id) AS CourseName, 
       count(o) AS OutcomeCount
ORDER BY OutcomeCount DESC
LIMIT 10;

// Query 5: Full End-to-End Dependency Traversal
MATCH path = (p:Program)-[:OFFERS_COURSE]->(c:Course)-[:ACHIEVES_OUTCOME]->(o:Outcome)
RETURN path
LIMIT 20;