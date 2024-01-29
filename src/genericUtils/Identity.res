external formReactEventToString: ReactEvent.Form.t => string = "%identity"
external stringToFormReactEvent: string => ReactEvent.Form.t = "%identity"
external anyTypeToReactEvent: 'a => ReactEvent.Form.t = "%identity"
external arrofStringToReactEvent: array<string> => ReactEvent.Form.t = "%identity"
external jsonToNullableJson: Js.Json.t => Js.Nullable.t<Js.Json.t> = "%identity"
external jsonToReactDOMStyle: Js.Json.t => ReactDOM.style = "%identity"
external genericTypeToJson: 'a => Js.Json.t = "%identity"
external genericTypeToBool: 'a => bool = "%identity"
external formReactEventToBool: ReactEvent.Form.t => bool = "%identity"
external genericObjectOrRecordToJson: {..} => Js.Json.t = "%identity"
external genericTypeToDictOfJson: 't => Dict.t<Js.Json.t> = "%identity"
external formReactEventToArrayOfString: ReactEvent.Form.t => array<string> = "%identity"
external jsonToFormReactEvent: Js.Json.t => ReactEvent.Form.t = "%identity"
external arrayOfGenericTypeToFormReactEvent: array<'a> => ReactEvent.Form.t = "%identity"
external webAPIFocusEventToReactEventFocus: Webapi.Dom.FocusEvent.t => ReactEvent.Focus.t =
  "%identity"
external toWasm: Dict.t<Js.Json.t> => RoutingTypes.wasmModule = "%identity"
