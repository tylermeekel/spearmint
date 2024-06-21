import gleam/json.{type Json}

pub type Person {
  Person(name: String, age: Int, description: String)
}

pub fn encode_person(person: Person) -> Json {
  json.object([
    #("name", json.string(person.name)),
    #("age", json.int(person.age)),
    #("description", json.string(person.description)),
  ])
}
