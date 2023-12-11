external formReactEventToString: ReactEvent.Form.t => string = "%identity"
external stringToFormReactEvent: string => ReactEvent.Form.t = "%identity"
external anyTypeToReactEvent: 'a => ReactEvent.Form.t = "%identity"
external arrofStringToReactEvent: array<string> => ReactEvent.Form.t = "%identity"
external jsonToNullableJson: Js.Json.t => Js.Nullable.t<Js.Json.t> = "%identity"
external jsonToReactDOMStyle: Js.Json.t => ReactDOM.style = "%identity"
