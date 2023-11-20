external strToFormEvent: Js.String.t => ReactEvent.Form.t = "%identity"
let validateConditionJson = json => {
  open LogicUtils
  let checkValue = dict => {
    dict
    ->getArrayFromDict("value", [])
    ->Js.Array2.filter(ele => {
      ele != ""->Js.Json.string
    })
    ->Js.Array2.length > 0 ||
    dict->getString("value", "") !== "" ||
    dict->getFloat("value", -1.0) !== -1.0 ||
    dict->getString("operator", "") == "IS NULL" ||
    dict->getString("operator", "") == "IS NOT NULL"
  }
  switch json->Js.Json.decodeObject {
  | Some(dict) =>
    ["operator", "real_field"]->Js.Array2.every(key =>
      dict->Js.Dict.get(key)->Belt.Option.isSome
    ) && dict->checkValue
  | None => false
  }
}

module TextView = {
  @react.component
  let make = (
    ~str,
    ~fontColor="text-jp-gray-800 dark:text-jp-gray-600",
    ~fontWeight="font-medium",
  ) => {
    str !== ""
      ? <AddDataAttributes attributes=[("data-plc-text", str)]>
          <div
            className={`text-opacity-75 dark:text-opacity-75 
              hover:text-opacity-100 dark:hover:text-opacity-100  
              mx-1  ${fontColor} ${fontWeight} `}>
            {React.string(str)}
          </div>
        </AddDataAttributes>
      : React.null
  }
}

module CompressedView = {
  @react.component
  let make = (~id, ~isFirst) => {
    open LogicUtils
    let conditionInput = ReactFinalForm.useField(id).input
    let condition =
      conditionInput.value
      ->Js.Json.decodeObject
      ->Belt.Option.flatMap(dict => {
        Some(
          dict->getString("logical.operator", ""),
          dict->getString("real_field", ""),
          dict->getString("operator", ""),
          dict
          ->getOptionStrArrayFromDict("value")
          ->Belt.Option.getWithDefault([dict->getString("value", "")]),
          dict->getDictfromDict("metadata")->getOptionString("key"),
        )
      })
    switch condition {
    | Some((logical, field, operator, value, key)) =>
      <div className="flex flex-wrap items-center gap-4">
        {if !isFirst {
          <TextView str=logical fontColor="text-blue-800" fontWeight="font-semibold" />
        } else {
          React.null
        }}
        <TextView str=field />
        {switch key {
        | Some(val) => <TextView str=val />
        | None => React.null
        }}
        <TextView str=operator fontColor="text-red-500" fontWeight="font-semibold" />
        <TextView str={value->Js.Array2.filter(ele => ele != "")->Js.Array2.joinWith(", ")} />
      </div>
    | None => React.null
    }
  }
}

module LogiacalOps = {
  @react.component
  let make = (~id) => {
    open LogicUtils
    let logicalOperatorInput = "[\"logical.operator\"]"

    let logicalOpsInput = ReactFinalForm.useField(`${id}.${logicalOperatorInput}`).input

    React.useEffect0(() => {
      if logicalOpsInput.value->getStringFromJson("") === "" {
        logicalOpsInput.onChange("AND"->strToFormEvent)
      }
      None
    })
    let onChange = str => logicalOpsInput.onChange(str->strToFormEvent)

    <ButtonGroup wrapperClass="flex flex-row mr-2 ml-1">
      {["AND", "OR"]
      ->Js.Array2.map(text => {
        let active = logicalOpsInput.value->getStringFromJson("") === text
        <Button
          text
          onClick={_ => onChange(text)}
          textStyle={active ? "text-blue-800" : ""}
          textWeight={active ? "font-semibold" : "font-medium"}
          customButtonStyle={active ? "shadow-inner px-0" : "px-0"}
          buttonType={active ? SecondaryFilled : Secondary}
        />
      })
      ->React.array}
    </ButtonGroup>
  }
}
