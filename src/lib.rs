use mlua::prelude::{Lua, LuaError, LuaResult, LuaTable};
use mlua::LuaSerdeExt;
use serde_yaml::Value as YamlValue;

fn yaml_to_lua<'lua>(lua: &'lua Lua, yamlstr: String) -> LuaResult<mlua::Value<'lua>> {
    let yaml: YamlValue = serde_yaml::from_str(&yamlstr).map_err(LuaError::external)?;

    lua.to_value(&yaml)
}

#[mlua::lua_module]
fn libgh_actions_rust(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    exports.set("parse_yaml", lua.create_function(yaml_to_lua)?)?;

    Ok(exports)
}
