open AdvancedRoutingTypes
open AdvancedRoutingUtils
open FormRenderer

external arrToFormEvent: array<'a> => ReactEvent.Form.t = "%identity"
external toForm: 'a => ReactEvent.Form.t = "%identity"
external strToFormEvent: Js.String.t => ReactEvent.Form.t = "%identity"
external formEventToStr: ReactEvent.Form.t => string = "%identity"
external formEventToStrArr: ReactEvent.Form.t => array<string> = "%identity"

module LogicalOps = {
  @react.component
  let make = (~id) => {
    let logicalOpsInput = ReactFinalForm.useField(`${id}.logical`).input

    React.useEffect0(() => {
      if logicalOpsInput.value->LogicUtils.getStringFromJson("")->Js.String2.length === 0 {
        logicalOpsInput.onChange("AND"->strToFormEvent)
      }
      None
    })
    let onChange = str => logicalOpsInput.onChange(str->strToFormEvent)

    <ButtonGroup wrapperClass="flex flex-row mr-2 ml-1">
      {["AND", "OR"]
      ->Js.Array2.map(text => {
        let active = logicalOpsInput.value->LogicUtils.getStringFromJson("") === text
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

module OperatorInp = {
  @react.component
  let make = (~fieldsArray: array<ReactFinalForm.fieldRenderProps>, ~keyType) => {
    let defaultInput: ReactFinalForm.fieldRenderProps = {
      input: ReactFinalForm.makeInputRecord(""->Js.Json.string, _e => ()),
      meta: ReactFinalForm.makeCustomError(None),
    }
    let field = (fieldsArray->Belt.Array.get(0)->Belt.Option.getWithDefault(defaultInput)).input
    let operator = (fieldsArray->Belt.Array.get(1)->Belt.Option.getWithDefault(defaultInput)).input
    let valInp = (fieldsArray->Belt.Array.get(2)->Belt.Option.getWithDefault(defaultInput)).input
    let (opVals, setOpVals) = React.useState(_ => [])

    let input: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ev => (),
      onChange: ev => {
        let value = ev->formEventToStr
        operator.onChange(value->toForm)
      },
      onFocus: _ev => (),
      value: operator.value,
      checked: true,
    }
    React.useEffect2(() => {
      let operatorVals = switch keyType->variantTypeMapper {
      | Enum_variant => ["IS", "CONTAINS", "IS_NOT", "NOT_CONTAINS"]
      | Number => ["EQUAL TO", "GREATER THAN", "LESS THAN"]
      | Metadata_value => ["EQUAL TO"]
      | String_value => ["EQUAL TO", "NOT EQUAL_TO"]
      | _ => []
      }

      setOpVals(_ => operatorVals)

      if operator.value->Js.Json.decodeString->Belt.Option.isNone {
        operator.onChange(operatorVals[0]->toForm)
      }
      None
    }, (field.value, valInp.value))
    let descriptionDict =
      [
        ("IS", "Includes only results that exactly match the filter value(s)."),
        ("CONTAINS", "Includes only results with any value for the filter property."),
        ("IS_NOT", "Includes results that does not match the filter value(s)."),
        ("NOT_CONTAINS", "Includes results except any value for the filter property."),
      ]->Js.Dict.fromArray
    let disableSelect =
      field.value->Js.Json.decodeString->Belt.Option.getWithDefault("")->Js.String2.length === 0

    let operatorOptions = opVals->Js.Array2.map(opVal => {
      let obj: SelectBox.dropdownOption = {
        label: opVal,
        value: opVal,
      }

      switch descriptionDict->Js.Dict.get(opVal) {
      | Some(description) => {...obj, description}
      | None => obj
      }
    })
    let textColorStyle = disableSelect ? "text-hyperswitch_red opacity-50" : "text-hyperswitch_red"
    <SelectBox.BaseDropdown
      allowMultiSelect=false
      buttonText="Select Operator"
      input
      options=operatorOptions
      hideMultiSelectButtons=true
      textStyle={`text-body ${textColorStyle}`}
      disableSelect
    />
  }
}

module ValueInp = {
  @react.component
  let make = (~fieldsArray: array<ReactFinalForm.fieldRenderProps>, ~variantValues, ~keyType) => {
    let valueField = (
      fieldsArray[1]->Belt.Option.getWithDefault(ReactFinalForm.fakeFieldRenderProps)
    ).input
    let opField = (
      fieldsArray[2]->Belt.Option.getWithDefault(ReactFinalForm.fakeFieldRenderProps)
    ).input
    let typeField = (
      fieldsArray[3]->Belt.Option.getWithDefault(ReactFinalForm.fakeFieldRenderProps)
    ).input

    React.useEffect1(() => {
      typeField.onChange(
        if keyType->variantTypeMapper === Metadata_value {
          "metadata_variant"
        } else if keyType->variantTypeMapper === String_value {
          "str_value"
        } else {
          switch opField.value->LogicUtils.getStringFromJson("")->operatorMapper {
          | IS
          | IS_NOT => "enum_variant"
          | CONTAINS
          | NOT_CONTAINS => "enum_variant_array"
          | _ => "number"
          }
        }->toForm,
      )
      None
    }, [valueField.value])

    let input: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ev => (),
      onChange: ev => {
        let value = ev->formEventToStrArr
        valueField.onChange(value->toForm)
      },
      onFocus: _ev => (),
      value: valueField.value,
      checked: true,
    }

    switch opField.value->LogicUtils.getStringFromJson("")->operatorMapper {
    | CONTAINS | NOT_CONTAINS =>
      <SelectBox.BaseDropdown
        allowMultiSelect=true
        buttonText="Select Value"
        input
        options={variantValues->SelectBox.makeOptions}
        hideMultiSelectButtons=true
        showSelectionAsChips={false}
      />
    | IS | IS_NOT => {
        let val = valueField.value->LogicUtils.getStringFromJson("")
        <SelectBox.BaseDropdown
          allowMultiSelect=false
          buttonText={val->Js.String2.length === 0 ? "Select Value" : val}
          input
          options={variantValues->SelectBox.makeOptions}
          hideMultiSelectButtons=true
          fixedDropDownDirection=SelectBox.TopRight
        />
      }
    | EQUAL_TO =>
      switch keyType->variantTypeMapper {
      | String_value => <TextInput input placeholder="Enter value" />
      | _ => <NumericTextInput placeholder={"Enter value"} input />
      }

    | NOT_EQUAL_TO => <TextInput input placeholder="Enter value" />
    | LESS_THAN | GREATER_THAN => <NumericTextInput placeholder={"Enter value"} input />

    | _ => React.null
    }
  }
}

module MetadataInp = {
  @react.component
  let make = (~fieldsArray: array<ReactFinalForm.fieldRenderProps>, ~keyType) => {
    let valueField = (
      fieldsArray[2]->Belt.Option.getWithDefault(ReactFinalForm.fakeFieldRenderProps)
    ).input

    let textInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ev => {
        let value = valueField.value
        let val = value->LogicUtils.getStringFromJson("")
        let valSplit = Js.String2.split(val, ",")
        let arrStr = valSplit->Js.Array2.map(item => {
          Js.String2.trim(item)
        })
        let finalVal = Js.Array2.joinWith(arrStr, ",")->Js.Json.string

        valueField.onChange(finalVal->toForm)
      },
      onChange: ev => {
        let target = ReactEvent.Form.target(ev)
        let value = target["value"]
        valueField.onChange(value->toForm)
      },
      onFocus: _ev => (),
      value: valueField.value,
      checked: true,
    }
    <UIUtils.RenderIf condition={keyType->variantTypeMapper === Metadata_value}>
      <TextInput placeholder={"Enter Key"} input=textInput />
    </UIUtils.RenderIf>
  }
}

let renderOperatorInp = (keyType, fieldsArray: array<ReactFinalForm.fieldRenderProps>) => {
  <OperatorInp fieldsArray keyType />
}
let renderValueInp = (
  keyType: string,
  variantValues,
  fieldsArray: array<ReactFinalForm.fieldRenderProps>,
) => {
  <ValueInp fieldsArray variantValues keyType />
}

let renderMetaInput = (keyType, fieldsArray: array<ReactFinalForm.fieldRenderProps>) => {
  <MetadataInp fieldsArray keyType />
}

let operatorInput = (id, keyType) => {
  makeMultiInputFieldInfoOld(
    ~label="",
    ~comboCustomInput=renderOperatorInp(keyType),
    ~inputFields=[
      makeInputFieldInfo(~name=`${id}.lhs`, ()),
      makeInputFieldInfo(~name=`${id}.comparison`, ()),
      makeInputFieldInfo(~name=`${id}.value.value`, ()),
    ],
    (),
  )
}

let valueInput = (id, variantValues, keyType) => {
  let valuePath = if keyType->variantTypeMapper === Metadata_value {
    `value.value.value`
  } else {
    `value.value`
  }
  makeMultiInputFieldInfoOld(
    ~label="",
    ~comboCustomInput=renderValueInp(keyType, variantValues),
    ~inputFields=[
      makeInputFieldInfo(~name=`${id}.lhs`, ()),
      makeInputFieldInfo(~name=`${id}.${valuePath}`, ()),
      makeInputFieldInfo(~name=`${id}.comparison`, ()),
      makeInputFieldInfo(~name=`${id}.value.type`, ()),
    ],
    (),
  )
}
let metaInput = (id, keyType) =>
  makeMultiInputFieldInfoOld(
    ~label="",
    ~comboCustomInput=renderMetaInput(keyType),
    ~inputFields=[
      makeInputFieldInfo(~name=`${id}.value`, ()),
      makeInputFieldInfo(~name=`${id}.operator`, ()),
      makeInputFieldInfo(~name=`${id}.value.value.key`, ()),
    ],
    (),
  )

module FieldInp = {
  @react.component
  let make = (~ops, ~prefix, ~onChangeMethod) => {
    let field = ReactFinalForm.useField(`${prefix}.lhs`).input
    let op = ReactFinalForm.useField(`${prefix}.comparison`).input
    let val = ReactFinalForm.useField(`${prefix}.value.value`).input

    let input: ReactFinalForm.fieldRenderPropsInput = {
      name: "string",
      onBlur: _ev => (),
      onChange: ev => {
        let value = ev->formEventToStr
        onChangeMethod(value)
        field.onChange(value->toForm)
        op.onChange(""->toForm)
        val.onChange(""->toForm)
      },
      onFocus: _ev => (),
      value: field.value,
      checked: true,
    }

    let options = ops->Js.Array2.map((op): SelectBox.dropdownOption => {
      {value: op, label: op}
    })

    <SelectBox.BaseDropdown
      allowMultiSelect=false buttonText="Select Field" input options hideMultiSelectButtons=true
    />
  }
}

module RuleFieldBase = {
  @react.component
  let make = (~isFirst, ~id, ~isExpanded, ~onClick, ~wasm) => {
    let (hover, setHover) = React.useState(_ => false)
    let (paymentMethod, setpaymentMethod) = React.useState(_ => [])
    let (keyType, setKeyType) = React.useState(_ => "")
    let (variantValues, setVariantValues) = React.useState(_ => [])
    let field = ReactFinalForm.useField(`${id}.lhs`).input

    let setKeyTypeAndVariants = (wasm, value) => {
      let keyType = getWasmKeyType(wasm, value)
      let keyVariant = keyType->variantTypeMapper
      if keyVariant !== Number || keyVariant !== Metadata_value {
        let variantValues = getWasmVariantValues(wasm, value)
        setVariantValues(_ => variantValues)
      }
      setKeyType(_ => keyType)
    }

    let onChangeMethod = value => {
      setKeyTypeAndVariants(wasm, value)
    }

    React.useEffect0(() => {
      let methodKeys = switch wasm {
      | Some(res) => res.getAllKeys()
      | None => []
      }
      let value = field.value->LogicUtils.getStringFromJson("")
      if value->Js.String2.length > 0 {
        setKeyTypeAndVariants(wasm, value)
      }
      setpaymentMethod(_ => methodKeys)
      None
    })

    <UIUtils.RenderIf condition={paymentMethod->Js.Array2.length > 0}>
      {if isExpanded {
        <div
          className={`flex flex-wrap items-center px-1 ${hover
              ? "rounded-md bg-white dark:bg-black shadow"
              : ""}`}>
          <UIUtils.RenderIf condition={!isFirst}>
            <LogicalOps id />
          </UIUtils.RenderIf>
          <div className="-mt-5 p-1">
            <FieldWrapper label="">
              <FieldInp ops=paymentMethod prefix=id onChangeMethod />
            </FieldWrapper>
          </div>
          <div className="-mt-5">
            <FieldRenderer field={metaInput(id, keyType)} />
          </div>
          <div className="-mt-5">
            <FieldRenderer field={operatorInput(id, keyType)} />
          </div>
          <div className="-mt-5">
            <FieldRenderer field={valueInput(id, variantValues, keyType)} />
          </div>
          <UIUtils.RenderIf condition={!isFirst}>
            <div
              onClick
              onMouseEnter={_ => setHover(_ => true)}
              onMouseLeave={_ => setHover(_ => false)}
              className="flex items-center cursor-pointer rounded-full  border border-jp-gray-500 dark:border-jp-gray-960 bg-red-400 hover:shadow focus:outline-none p-2">
              <Icon size=10 className="text-gray-50 font-semibold" name="close" />
            </div>
          </UIUtils.RenderIf>
        </div>
      } else {
        <MakeRuleFieldComponent.CompressedView isFirst id />
      }}
    </UIUtils.RenderIf>
  }
}

module MakeRuleField = {
  @react.component
  let make = (~id, ~isExpanded, ~wasm) => {
    let ruleJsonPath = `${id}.statements`
    let conditionsInput = ReactFinalForm.useField(ruleJsonPath).input
    let fields = conditionsInput.value->Js.Json.decodeArray->Belt.Option.getWithDefault([])
    let plusBtnEnabled = true
    //fields->Js.Array2.every(validateConditionJson)
    let onPlusClick = _ => {
      if plusBtnEnabled {
        let toAdd = Js.Dict.empty()
        conditionsInput.onChange(Js.Array2.concat(fields, [toAdd->Js.Json.object_])->arrToFormEvent)
      }
    }

    let onCrossClick = index => {
      conditionsInput.onChange(fields->Array.filterWithIndex((_, i) => index !== i)->arrToFormEvent)
    }

    <div className="flex flex-wrap items-center">
      {Array.mapWithIndex(fields, (_, i) =>
        <RuleFieldBase
          onClick={_ => onCrossClick(i)}
          isFirst={i === 0}
          id={`${ruleJsonPath}[${i->Belt.Int.toString}]`}
          isExpanded
          wasm
        />
      )->React.array}
      {if isExpanded {
        <div
          onClick={onPlusClick}
          className={`focus:outline-none p-2 ml-8 mt-2 md:mt-0 flex items-center bg-white dark:bg-jp-gray-darkgray_background 
           rounded-full border border-jp-gray-500 dark:border-jp-gray-960 
           text-jp-gray-900 dark:text-jp-gray-text_darktheme   
          ${plusBtnEnabled
              ? "cursor-pointer text-opacity-75 dark:text-opacity-50 
                hover:text-opacity-100 dark:hover:text-opacity-75 hover:shadow"
              : "cursor-not-allowed text-opacity-50 dark:text-opacity-50"}`}>
          <Icon size=14 name="plus" />
        </div>
      } else {
        <Icon size=14 name="arrow-right" className="ml-4" />
      }}
    </div>
  }
}

let configurationNameInput = makeFieldInfo(
  ~label="Configuration Name",
  ~name="name",
  ~isRequired=true,
  ~placeholder="Enter Configuration Name",
  ~customInput=InputFields.textInput(~autoFocus=true, ()),
  (),
)
let descriptionInput = makeFieldInfo(
  ~label="Description",
  ~name="description",
  ~isRequired=true,
  ~placeholder="Add a description for your configuration",
  ~customInput=InputFields.multiLineTextInput(
    ~isDisabled=false,
    ~rows=Some(3),
    ~cols=None,
    ~customClass="text-sm",
    (),
  ),
  (),
)
