#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;
#[macro_use] extern crate rocket_contrib;
extern crate base62;

use rocket::http::Status;
use rocket::request::Form;
use rocket::response::{content, status, Redirect};
use rocket_contrib::databases::redis;
use rocket_contrib::databases::redis::Commands;

#[database("redis")]
struct RedisConn(redis::Connection);

#[derive(FromForm)]
struct Url {
    url: String,
}

#[get("/")]
fn index() -> content::Html<&'static str> {
    content::Html("
        <!doctype html>
        <form method=post>
            <input name=url type=url />
            <button>Shorten</button>
        </form>
    ")
}

#[post("/", data = "<form>")]
fn shorten(conn: RedisConn, form: Form<Url>) -> String {
    match conn.incr("count", 1) {
        Ok(new_count) => {
            let slug = base62::encode(new_count);
            match conn.hset(&slug, "url", &form.url) {
                Ok(()) => format!("https://slu.gg/{}", &slug),
                Err(e) => format!("Error: {}", e),
            }
        },
        Err(e) => format!("Missing count key: {}", e),
    }
}

#[get("/<slug>")]
fn redirect(conn: RedisConn, slug: String) -> Result<Redirect, status::Custom<String>> {
    match conn.hget::<_, _, Option<String>>(&slug, "url") {
        Ok(None) => Err(status::Custom(Status::NotFound, "no such slug".to_string())),
        Ok(Some(url)) => Ok(Redirect::to(url)),
        Err(e) => Err(status::Custom(Status::InternalServerError, format!("error: {}", e))),
    }
}

fn main() {
    rocket::ignite()
        .attach(RedisConn::fairing())
        .mount("/", routes![index, shorten, redirect])
        .launch();
}
