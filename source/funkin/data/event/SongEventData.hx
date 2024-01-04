package funkin.data.event;

import funkin.play.event.SongEvent;
import funkin.data.event.SongEventData.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.util.macro.ClassMacro;
import funkin.play.event.ScriptedSongEvent;

/**
 * This class statically handles the parsing of internal and scripted song event handlers.
 */
class SongEventParser
{
  /**
   * Every built-in event class must be added to this list.
   * Thankfully, with the power of `SongEventMacro`, this is done automatically.
   */
  static final BUILTIN_EVENTS:List<Class<SongEvent>> = ClassMacro.listSubclassesOf(SongEvent);

  /**
   * Map of internal handlers for song events.
   * These may be either `ScriptedSongEvents` or built-in classes extending `SongEvent`.
   */
  static final eventCache:Map<String, SongEvent> = new Map<String, SongEvent>();

  public static function loadEventCache():Void
  {
    clearEventCache();

    //
    // BASE GAME EVENTS
    //
    registerBaseEvents();
    registerScriptedEvents();
  }

  static function registerBaseEvents()
  {
    trace('Instantiating ${BUILTIN_EVENTS.length} built-in song events...');
    for (eventCls in BUILTIN_EVENTS)
    {
      var eventClsName:String = Type.getClassName(eventCls);
      if (eventClsName == 'funkin.play.event.SongEvent' || eventClsName == 'funkin.play.event.ScriptedSongEvent') continue;

      var event:SongEvent = Type.createInstance(eventCls, ["UNKNOWN"]);

      if (event != null)
      {
        trace('  Loaded built-in song event: (${event.id})');
        eventCache.set(event.id, event);
      }
      else
      {
        trace('  Failed to load built-in song event: ${Type.getClassName(eventCls)}');
      }
    }
  }

  static function registerScriptedEvents()
  {
    var scriptedEventClassNames:Array<String> = ScriptedSongEvent.listScriptClasses();
    if (scriptedEventClassNames == null || scriptedEventClassNames.length == 0) return;

    trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');
    for (eventCls in scriptedEventClassNames)
    {
      var event:SongEvent = ScriptedSongEvent.init(eventCls, "UKNOWN");

      if (event != null)
      {
        trace('  Loaded scripted song event: ${event.id}');
        eventCache.set(event.id, event);
      }
      else
      {
        trace('  Failed to instantiate scripted song event class: ${eventCls}');
      }
    }
  }

  public static function listEventIds():Array<String>
  {
    return eventCache.keys().array();
  }

  public static function listEvents():Array<SongEvent>
  {
    return eventCache.values();
  }

  public static function getEvent(id:String):SongEvent
  {
    return eventCache.get(id);
  }

  public static function getEventSchema(id:String):SongEventSchema
  {
    var event:SongEvent = getEvent(id);
    if (event == null) return null;

    return event.getEventSchema();
  }

  static function clearEventCache()
  {
    eventCache.clear();
  }

  public static function handleEvent(data:SongEventData):Void
  {
    var eventType:String = data.event;
    var eventHandler:SongEvent = eventCache.get(eventType);

    if (eventHandler != null)
    {
      eventHandler.handleEvent(data);
    }
    else
    {
      trace('WARNING: No event handler for event with id: ${eventType}');
    }

    data.activated = true;
  }

  public static inline function handleEvents(events:Array<SongEventData>):Void
  {
    for (event in events)
    {
      handleEvent(event);
    }
  }

  /**
   * Given a list of song events and the current timestamp,
   * return a list of events that should be handled.
   */
  public static function queryEvents(events:Array<SongEventData>, currentTime:Float):Array<SongEventData>
  {
    return events.filter(function(event:SongEventData):Bool {
      // If the event is already activated, don't activate it again.
      if (event.activated) return false;

      // If the event is in the future, don't activate it.
      if (event.time > currentTime) return false;

      return true;
    });
  }

  /**
   * Reset activation of all the provided events.
   */
  public static function resetEvents(events:Array<SongEventData>):Void
  {
    for (event in events)
    {
      event.activated = false;
      // TODO: Add an onReset() method to SongEvent?
    }
  }
}

@:forward(name, title, type, keys, min, max, step, defaultValue, iterator)
abstract SongEventSchema(SongEventSchemaRaw)
{
  public function new(?fields:Array<SongEventSchemaField>)
  {
    this = fields;
  }

  @:arrayAccess
  public function getByName(name:String):SongEventSchemaField
  {
    for (field in this)
    {
      if (field.name == name) return field;
    }

    return null;
  }

  public function getFirstField():SongEventSchemaField
  {
    return this[0];
  }

  public function stringifyFieldValue(name:String, value:Dynamic):String
  {
    var field:SongEventSchemaField = getByName(name);
    if (field == null) return 'Unknown';

    switch (field.type)
    {
      case SongEventFieldType.STRING:
        return Std.string(value);
      case SongEventFieldType.INTEGER:
        return Std.string(value);
      case SongEventFieldType.FLOAT:
        return Std.string(value);
      case SongEventFieldType.BOOL:
        return Std.string(value);
      case SongEventFieldType.ENUM:
        for (key in field.keys.keys())
        {
          if (field.keys.get(key) == value) return key;
        }
        return Std.string(value);
      default:
        return 'Unknown';
    }
  }

  @:arrayAccess
  public inline function get(key:Int)
  {
    return this[key];
  }

  @:arrayAccess
  public inline function arrayWrite(k:Int, v:SongEventSchemaField):SongEventSchemaField
  {
    return this[k] = v;
  }
}

typedef SongEventSchemaRaw = Array<SongEventSchemaField>;

typedef SongEventSchemaField =
{
  /**
   * The name of the property as it should be saved in the event data.
   */
  name:String,

  /**
   * The title of the field to display in the UI.
   */
  title:String,

  /**
   * The type of the field.
   */
  type:SongEventFieldType,

  /**
   * Used only for ENUM values.
   * The key is the display name and the value is the actual value.
   */
  ?keys:Map<String, Dynamic>,

  /**
   * Used for INTEGER and FLOAT values.
   * The minimum value that can be entered.
   * @default No minimum
   */
  ?min:Float,

  /**
   * Used for INTEGER and FLOAT values.
   * The maximum value that can be entered.
   * @default No maximum
   */
  ?max:Float,

  /**
   * Used for INTEGER and FLOAT values.
   * The step value that will be used when incrementing/decrementing the value.
   * @default `0.1`
   */
  ?step:Float,

  /**
   * An optional default value for the field.
   */
  ?defaultValue:Dynamic,
}

enum abstract SongEventFieldType(String) from String to String
{
  /**
   * The STRING type will display as a text field.
   */
  var STRING = "string";

  /**
   * The INTEGER type will display as a text field that only accepts numbers.
   */
  var INTEGER = "integer";

  /**
   * The FLOAT type will display as a text field that only accepts numbers.
   */
  var FLOAT = "float";

  /**
   * The BOOL type will display as a checkbox.
   */
  var BOOL = "bool";

  /**
   * The ENUM type will display as a dropdown.
   * Make sure to specify the `keys` field in the schema.
   */
  var ENUM = "enum";
}
