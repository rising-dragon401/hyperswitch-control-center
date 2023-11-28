open ConnectorTypes

type colType =
  Name | TestMode | Status | Actions | ProfileId | ProfileName | ConnectorLabel | PaymentMethods

let defaultColumns = [
  Name,
  ProfileId,
  ProfileName,
  ConnectorLabel,
  Status,
  TestMode,
  Actions,
  PaymentMethods,
]

module ConnectorActions = {
  @react.component
  let make = () => {
    let onClick = e => {
      e->ReactEvent.Mouse.stopPropagation
    }

    <div>
      <div className="invisible cursor-pointer group-hover:visible flex">
        <div className="mr-5">
          <ToolTip
            tooltipWidthClass="w-fit"
            description="Delete"
            toolTipFor={<Icon
              name="delete"
              size=15
              className="text-jp-gray-700 dark:hover:text-white hover:text-jp-gray-900 "
              onClick
            />}
            toolTipPosition=Left
            tooltipPositioning=#absolute
          />
        </div>
      </div>
    </div>
  }
}

let parsePaymentMethodType = paymentMethodType => {
  open LogicUtils

  let paymentMethodTypeDict = paymentMethodType->getDictFromJsonObject
  {
    payment_method_type: paymentMethodTypeDict->getString("payment_method_type", ""),
    flow: paymentMethodTypeDict->getString("flow", ""),
    action: paymentMethodTypeDict->getString("action", ""),
  }
}

let parsePaymentMethod = paymentMethod => {
  open LogicUtils

  let paymentMethodDict = paymentMethod->getDictFromJsonObject
  let payment_method_types =
    paymentMethodDict
    ->getArrayFromDict("payment_method_types", [])
    ->Js.Array2.map(parsePaymentMethodType)

  {
    payment_method: paymentMethodDict->getString("payment_method", ""),
    payment_method_types,
  }
}

let convertFRMConfigJsonToObj = json => {
  open LogicUtils

  json->Js.Array2.map(config => {
    let configDict = config->getDictFromJsonObject
    let payment_methods =
      configDict->getArrayFromDict("payment_methods", [])->Js.Array2.map(parsePaymentMethod)

    {
      gateway: configDict->getString("gateway", ""),
      payment_methods,
    }
  })
}

let getPaymentMethodTypes = dict => {
  open LogicUtils
  {
    payment_method_type: dict->getString("payment_method_type", ""),
    payment_experience: dict->getString("payment_method_type", ""),
    card_networks: dict->getStrArrayFromDict("card_networks", []),
    accepted_countries: {
      options: {
        type_: "",
        list: [],
      },
    },
    accepted_currencies: {
      options: {
        type_: "",
        list: [],
      },
    },
    minimum_amount: dict->getInt("minimum_amount", 0),
    maximum_amount: dict->getInt("maximum_amount", 0),
    recurring_enabled: dict->getBool("recurring_enabled", false),
    installment_payment_enabled: dict->getBool("installment_payment_enabled", false),
  }
}

let getPaymentMethodsEnabled: Js.Dict.t<Js.Json.t> => paymentMethodEnabledType = dict => {
  open LogicUtils
  {
    payment_method: dict->getString("payment_method", ""),
    payment_method_types: dict
    ->Js.Dict.get("payment_method_types")
    ->Belt.Option.getWithDefault(Js.Dict.empty()->Js.Json.object_)
    ->getArrayDataFromJson(getPaymentMethodTypes),
  }
}

let getConnectorAccountDetails = dict => {
  open LogicUtils
  {
    auth_type: dict->getString("auth_type", ""),
    api_secret: dict->getString("api_secret", ""),
    api_key: dict->getString("api_key", ""),
    key1: dict->getString("key1", ""),
  }
}

let getProcessorPayloadType = dict => {
  open LogicUtils
  {
    connector_type: dict->getString("connector_type", ""),
    connector_name: dict->getString("connector_name", ""),
    connector_label: dict->getString("connector_label", ""),
    connector_account_details: dict
    ->getObj("connector_account_details", Js.Dict.empty())
    ->getConnectorAccountDetails,
    test_mode: dict->getBool("test_mode", true),
    disabled: dict->getBool("disabled", true),
    payment_methods_enabled: dict
    ->Js.Dict.get("payment_methods_enabled")
    ->Belt.Option.getWithDefault(Js.Dict.empty()->Js.Json.object_)
    ->getArrayDataFromJson(getPaymentMethodsEnabled),
    profile_id: dict->getString("profile_id", ""),
    merchant_connector_id: dict->getString("merchant_connector_id", ""),
    frm_configs: dict->getArrayFromDict("frm_configs", [])->convertFRMConfigJsonToObj,
  }
}

let getArrayOfConnectorListPayloadType = json => {
  open LogicUtils
  json
  ->getArrayFromJson([])
  ->Js.Array2.map(connectorJson => {
    connectorJson->getDictFromJsonObject->getProcessorPayloadType
  })
}

let getConnectorNameViaId = (
  connectorList: array<ConnectorTypes.connectorPayload>,
  mca_id: string,
) => {
  connectorList
  ->Js.Array2.find(ele => {ele.merchant_connector_id == mca_id})
  ->Belt.Option.getWithDefault(Js.Dict.empty()->getProcessorPayloadType)
}

let getAllPaymentMethods = (paymentMethodsArray: array<paymentMethodEnabledType>) => {
  let paymentMethods = paymentMethodsArray->Array.reduce([], (acc, item) => {
    acc->Js.Array2.concat([item.payment_method->LogicUtils.capitalizeString])
  })
  paymentMethods
}

let getHeading = colType => {
  switch colType {
  | Name => Table.makeHeaderInfo(~key="connector_name", ~title="Processor", ~showSort=false, ())
  | TestMode => Table.makeHeaderInfo(~key="test_mode", ~title="Test Mode", ~showSort=false, ())
  | Status => Table.makeHeaderInfo(~key="disabled", ~title="Status", ~showSort=false, ())
  | Actions => Table.makeHeaderInfo(~key="actions", ~title="", ~showSort=false, ())
  | ProfileId => Table.makeHeaderInfo(~key="profile_id", ~title="Profile Id", ~showSort=false, ())
  | ProfileName =>
    Table.makeHeaderInfo(~key="profile_name", ~title="Profile Name", ~showSort=false, ())
  | ConnectorLabel =>
    Table.makeHeaderInfo(~key="connector_label", ~title="Label", ~showSort=false, ())
  | PaymentMethods =>
    Table.makeHeaderInfo(~key="payment_methods", ~title="Payment Methods", ~showSort=false, ())
  }
}

let getCell = (connector: connectorPayload, colType): Table.cell => {
  switch colType {
  | Name => Text(connector.connector_name->LogicUtils.getTitle)
  | TestMode => Text(connector.test_mode ? "True" : "False")
  | Status =>
    Label({
      title: (connector.disabled ? "Disabled" : "Enabled")->Js.String2.toUpperCase,
      color: connector.disabled ? LabelRed : LabelGreen,
    })
  | ProfileId => Text(connector.profile_id)
  | ProfileName =>
    Table.CustomCell(
      <HSwitchMerchantAccountUtils.BusinessProfile profile_id={connector.profile_id} />,
      "",
    )
  | ConnectorLabel => Text(connector.connector_label)

  // | Actions =>
  //   Table.CustomCell(<ConnectorActions connector_id={connector.merchant_connector_id} />, "")
  | Actions => Table.CustomCell(<div />, "")
  | PaymentMethods =>
    Table.CustomCell(
      <div>
        {connector.payment_methods_enabled
        ->getAllPaymentMethods
        ->Js.Array2.joinWith(", ")
        ->React.string}
      </div>,
      "",
    )
  }
}

let connectorsTableDefaultColumns = Recoil.atom(. "connectorsTableDefaultColumns", defaultColumns)

let getArrayDataFromJson = (json, itemToObjMapper: Js.Dict.t<Js.Json.t> => connectorPayload) => {
  json
  ->HSwitchUtils.getProcessorsListFromJson()
  ->Js.Array2.map(itemToObjMapper)
  ->Js.Array2.filter(item => !(item.connector_name->Js.String2.includes("apple")))
}

let comparatorFunction = (connector1: connectorPayload, connector2: connectorPayload) => {
  connector1.connector_name->Js.String2.localeCompare(connector2.connector_name)->Belt.Float.toInt
}

let sortPreviouslyConnectedList = arr => {
  Js.Array2.sortInPlaceWith(arr, comparatorFunction)
}

let getPreviouslyConnectedList: Js.Json.t => array<connectorPayload> = json => {
  json->getArrayDataFromJson(getProcessorPayloadType)->sortPreviouslyConnectedList
}

let connectorEntity = (path: string) => {
  EntityType.makeEntity(
    ~uri=``,
    ~getObjects=getPreviouslyConnectedList,
    ~defaultColumns,
    ~getHeading,
    ~getCell,
    ~dataKey="",
    ~getShowLink={
      connec => `/${path}/${connec.merchant_connector_id}?name=${connec.connector_name}`
    },
    (),
  )
}
