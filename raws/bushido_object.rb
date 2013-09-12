require './raws/bushido_object_base'
require './util/opt'

BushidoObject = DEBUG ? SafeBushidoObject : BushidoObjectBase
