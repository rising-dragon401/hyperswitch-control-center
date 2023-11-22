open HSwitchUtils
open HomeUtils

module HomePageHorizontalStepper = {
  @react.component
  let make = (~stepperItemsArray: array<string>, ~className="") => {
    let enumDetails = Recoil.useRecoilValueFromAtom(HyperswitchAtom.enumVariantAtom)
    let typedValueOfEnum = enumDetails->LogicUtils.safeParse->QuickStartUtils.getTypedValueFromDict

    // TODO : To be used when Test Payment flow if is integrated
    let step = if !(typedValueOfEnum.testPayment.payment_id->Js.String2.length > 0) {
      0
    } else if !typedValueOfEnum.integrationCompleted {
      1
    } else {
      2
    }

    // let step = if !(typedValueOfEnum.firstProcessorConnected.processorID->Js.String2.length > 0) {
    //   0
    // } else if (
    //   typedValueOfEnum.isMultipleConfiguration &&
    //   !(typedValueOfEnum.configuredRouting.routing_id->Js.String2.length > 0)
    // ) {
    //   0
    // } else if !typedValueOfEnum.integrationCompleted {
    //   1
    // } else {
    //   2
    // }

    let getStepperStyle = index => {
      index <= step ? "bg-blue-700 text-white border-transparent" : "border-blue-700 text-blue-700 "
    }
    let getProgressBarStyle = index => {
      if index < step {
        "bg-blue-700  w-full"
      } else if index === step {
        "bg-blue-700  w-1/2"
      } else {
        ""
      }
    }

    let getTextStyle = `${getTextClass(~textVariant=P2, ~paragraphTextVariant=Medium, ())} `

    <div className="flex w-full gap-2 justify-evenly">
      {stepperItemsArray
      ->Array.mapWithIndex((value, index) => {
        <div className="flex flex-col gap-2.5 w-full">
          <div className="flex items-center gap-2">
            <span
              className={`h-6 w-6 flex items-center justify-center border-2 rounded-md font-semibold ${index->getStepperStyle} ${getTextStyle}`}>
              {(index + 1)->string_of_int->React.string}
            </span>
            <UIUtils.RenderIf condition={index !== stepperItemsArray->Js.Array2.length - 1}>
              <div className="relative w-full">
                <div className={`absolute h-1 rounded-full z-1 ${index->getProgressBarStyle}`} />
                <div className="w-full h-1 rounded-full bg-grey-700 bg-opacity-10" />
              </div>
            </UIUtils.RenderIf>
          </div>
          <p> {value->React.string} </p>
        </div>
      })
      ->React.array}
    </div>
  }
}

module QuickStart = {
  @react.component
  let make = (~isMobileView) => {
    let {setDashboardPageState, setQuickStartPageState} = React.useContext(
      GlobalProvider.defaultContext,
    )
    let usePostEnumDetails = EnumVariantHook.usePostEnumDetails()
    let updateEnumInRecoil = EnumVariantHook.useUpdateEnumInRecoil()
    let (configureButtonState, setConfigureButtonState) = React.useState(_ => Button.Normal)
    let connectorList =
      HyperswitchAtom.connectorListAtom->Recoil.useRecoilValueFromAtom->LogicUtils.safeParse
    let initalEnums =
      HyperswitchAtom.enumVariantAtom->Recoil.useRecoilValueFromAtom->LogicUtils.safeParse
    let typedValueOfEnum = initalEnums->QuickStartUtils.getTypedValueFromDict

    let setEnumsForPreviouslyConnectedConnectors = async () => {
      open ConnectorTableUtils
      try {
        setConfigureButtonState(_ => Button.Loading)
        let typedConnectorValue = connectorList->getArrayOfConnectorListPayloadType

        if (
          !typedValueOfEnum.isMultipleConfiguration &&
          typedValueOfEnum.firstProcessorConnected.processorID->Js.String2.length === 0 &&
          typedValueOfEnum.secondProcessorConnected.processorID->Js.String2.length === 0
        ) {
          if typedConnectorValue->Js.Array2.length >= 2 {
            let firstConnectorValue =
              typedConnectorValue
              ->Belt.Array.get(0)
              ->Belt.Option.getWithDefault(getProcessorPayloadType(Js.Dict.empty()))

            let secondConnectorValue =
              typedConnectorValue
              ->Belt.Array.get(1)
              ->Belt.Option.getWithDefault(getProcessorPayloadType(Js.Dict.empty()))

            let bodyOfFirstConnector: QuickStartTypes.processorType = {
              processorID: firstConnectorValue.merchant_connector_id,
              processorName: firstConnectorValue.connector_name,
            }

            let bodyOfSecondConnector: QuickStartTypes.processorType = {
              processorID: secondConnectorValue.merchant_connector_id,
              processorName: secondConnectorValue.connector_name,
            }

            let _isMultipleConnectorSetup =
              await Boolean(true)->usePostEnumDetails(#IsMultipleConfiguration)
            let _firstEnumSetupValues =
              await ProcesorType(bodyOfFirstConnector)->usePostEnumDetails(#FirstProcessorConnected)
            let _secondEnumSetupValues =
              await ProcesorType(bodyOfSecondConnector)->usePostEnumDetails(
                #SecondProcessorConnected,
              )
            let _res = updateEnumInRecoil([
              (Boolean(true), #IsMultipleConfiguration),
              (ProcesorType(bodyOfFirstConnector), #FirstProcessorConnected),
              (ProcesorType(bodyOfSecondConnector), #SecondProcessorConnected),
            ])
            setQuickStartPageState(_ => ConnectProcessor(CONFIGURE_SMART_ROUTING))
          } else if typedConnectorValue->Js.Array2.length === 1 {
            let firstConnectorValue =
              typedConnectorValue
              ->Belt.Array.get(0)
              ->Belt.Option.getWithDefault(getProcessorPayloadType(Js.Dict.empty()))

            let bodyOfFirstConnector: QuickStartTypes.processorType = {
              processorID: firstConnectorValue.merchant_connector_id,
              processorName: firstConnectorValue.connector_name,
            }

            let _isMultipleConnectorSetup =
              await Boolean(true)->usePostEnumDetails(#IsMultipleConfiguration)
            let _firstEnumSetupValues =
              await ProcesorType(bodyOfFirstConnector)->usePostEnumDetails(#FirstProcessorConnected)
            let _res = updateEnumInRecoil([
              (Boolean(true), #IsMultipleConfiguration),
              (ProcesorType(bodyOfFirstConnector), #FirstProcessorConnected),
            ])
            setQuickStartPageState(_ => ConnectProcessor(CONFIGURE_SECONDARY))
          }
        } else {
          let pageStateToSet =
            initalEnums->LogicUtils.getDictFromJsonObject->QuickStartUtils.getCurrentStep
          setQuickStartPageState(_ => pageStateToSet->QuickStartUtils.enumToVarinatMapper)
        }
        setConfigureButtonState(_ => Button.Normal)
        setDashboardPageState(_ => #QUICK_START)
        RescriptReactRouter.push("/quick-start")
      } catch {
      | _ => setConfigureButtonState(_ => Button.Normal)
      }
    }

    let buttonText = if !(typedValueOfEnum.testPayment.payment_id->Js.String2.length > 0) {
      "Configure (Test mode)"
    } else if !typedValueOfEnum.integrationCompleted {
      "Start Integration on app"
    } else {
      "Get Production access"
    }

    <div className="flex flex-col md:flex-row pt-10 border rounded-md bg-white gap-4">
      <div className="flex flex-col justify-evenly gap-8 pl-10 pb-10 pr-2 md:pr-0">
        <div className="flex flex-col gap-2">
          <p className={getTextClass(~textVariant=H2, ())}> {"Quick Start"->React.string} </p>
          <p className=subtextStyle>
            {"Configure and start using Hyperswitch to get an overview of our offerings and how hyperswitch can help you control your payments"->React.string}
          </p>
        </div>
        <HomePageHorizontalStepper stepperItemsArray=HomeUtils.homepageStepperItems />
        <Button
          buttonState={configureButtonState}
          text=buttonText
          buttonType={Primary}
          customButtonStyle="group w-1/5"
          rightIcon={CustomIcon(
            <Icon
              name="thin-right-arrow"
              size=20
              className="group-hover:scale-125 cursor-pointer transition duration-200 ease-in-out"
            />,
          )}
          onClick={_ => {
            setEnumsForPreviouslyConnectedConnectors()->ignore
          }}
        />
      </div>
      <UIUtils.RenderIf condition={!isMobileView}>
        <div className="h-30 md:w-[43rem] flex justify-end">
          <img src="/assets/QuickStartImage.svg" />
        </div>
      </UIUtils.RenderIf>
    </div>
  }
}

module RecipesAndPlugins = {
  @react.component
  let make = () => {
    let enumDetails =
      HyperswitchAtom.enumVariantAtom
      ->Recoil.useRecoilValueFromAtom
      ->LogicUtils.safeParse
      ->QuickStartUtils.getTypedValueFromDict
    let isStripePlusPayPalCompleted = enumDetails->checkStripePlusPayPal
    let isWooCommercePalCompleted = enumDetails->checkWooCommerce

    <div className="flex flex-col gap-4">
      <p className=headingStyle> {"Recipes & Plugins"->React.string} </p>
      <div className="grid grid-cols-1 md:grid-cols-2 w-full gap-4">
        <div
          className={boxCssHover(~ishoverStyleRequired=!isStripePlusPayPalCompleted, ())}
          onClick={_ => RescriptReactRouter.push("stripe-plus-paypal")}>
          <div className="flex items-center gap-2">
            <p className=cardHeaderTextStyle> {"Use PayPal with Stripe"->React.string} </p>
            <Icon
              name="chevron-right"
              size=12
              className="group-hover:scale-125 transition duration-200 ease-in-out"
            />
            <UIUtils.RenderIf condition={isStripePlusPayPalCompleted}>
              <div className="flex ">
                <Icon name="success-tag" size=22 className="!w-32" />
              </div>
            </UIUtils.RenderIf>
          </div>
          <div className="flex gap-2 h-full">
            <p className=paragraphTextVariant>
              {"Get the best of Stripe's developer experience and Paypal's user base"->React.string}
            </p>
            <img src="/assets/StripePlusPaypal.svg" className=imageTransitionCss />
          </div>
        </div>
        <div
          className={boxCssHover(~ishoverStyleRequired=!isWooCommercePalCompleted, ())}
          onClick={_ => RescriptReactRouter.push("woocommerce")}>
          <div className="flex items-center gap-2">
            <p className=cardHeaderTextStyle> {"WooCommerce plugin"->React.string} </p>
            <Icon
              name="chevron-right"
              size=12
              className="group-hover:scale-125 transition duration-200 ease-in-out"
            />
            <UIUtils.RenderIf condition={isWooCommercePalCompleted}>
              <div className="flex ">
                <Icon name="success-tag" size=22 className="!w-32" />
              </div>
            </UIUtils.RenderIf>
          </div>
          <div className="flex gap-2 h-full">
            <p className=paragraphTextVariant>
              {"Give your shoppers a lightweight and embedded payment experience with our plugin"->React.string}
            </p>
            <img src="/assets/Woocommerce.svg" className=imageTransitionCss />
          </div>
        </div>
      </div>
    </div>
  }
}

module Resources = {
  @react.component
  let make = () => {
    let merchantDetailsValue = useMerchantDetailsValue()
    let (overlayPaymentModal, setOverlayPaymentModal) = React.useState(_ => false)
    let connectorListJson = HyperswitchAtom.connectorListAtom->Recoil.useRecoilValueFromAtom
    let isConfigureConnector =
      connectorListJson
      ->LogicUtils.safeParse
      ->ConnectorTableUtils.getArrayOfConnectorListPayloadType
      ->Js.Array2.length > 0
    let elements: array<HomeUtils.resourcesTypes> = [
      {
        id: "tryTheDemo",
        icon: "docs.svg",
        headerText: "Try a test payment",
        subText: "Experience the Hyperswitch Unified checkout using test credentials",
        redirectLink: "",
      },
      {
        id: "openSource",
        icon: "blogs.svg",
        headerText: "Contribute in open source",
        subText: "We welcome all your suggestions, feedbacks, and queries. Hop on to the Open source rail!",
        redirectLink: "",
      },
      {
        id: "developerdocs",
        icon: "connector.svg",
        headerText: "Developer docs",
        subText: "Everything you need to know to get to get the SDK up and running resides in here.",
        redirectLink: "",
      },
    ]
    <>
      <div className="flex flex-col gap-4">
        <p className=headingStyle> {"Resources"->React.string} </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {elements
          ->Array.mapWithIndex((item, index) => {
            <div
              className="group bg-white border rounded-md p-10 flex flex-col gap-4 group-hover:shadow hover:shadow-homePageBoxShadow cursor-pointer"
              key={index->string_of_int}
              onClick={_ => {
                if item.id === "openSource" {
                  "https://github.com/juspay/hyperswitch"->Window._open
                } else if item.id === "developerdocs" {
                  "https://hyperswitch.io/docs"->Window._open
                } else if item.id === "tryTheDemo" {
                  setOverlayPaymentModal(_ => true)
                }
              }}>
              <img src={`/icons/${item.icon}`} className="h-6 w-6" />
              <div className="flex items-center gap-2">
                <p className=cardHeaderText> {item.headerText->React.string} </p>
                <Icon
                  name="chevron-right"
                  size=12
                  className="group-hover:scale-125 transition duration-200 ease-in-out"
                />
              </div>
              <p className=paragraphTextVariant> {item.subText->React.string} </p>
            </div>
          })
          ->React.array}
        </div>
      </div>
      <HomeUtils.SDKOverlay
        merchantDetailsValue overlayPaymentModal setOverlayPaymentModal isConfigureConnector
      />
    </>
  }
}

@react.component
let make = () => {
  let isMobileView = MatchMedia.useMobileChecker()
  let {isProdIntentCompleted} = React.useContext(GlobalProvider.defaultContext)
  let enumDetails = Recoil.useRecoilValueFromAtom(HyperswitchAtom.enumVariantAtom)
  let typedEnumValue = enumDetails->LogicUtils.safeParse->QuickStartUtils.getTypedValueFromDict

  let checkingConditions = [
    typedEnumValue.testPayment.payment_id->Js.String2.length > 0,
    typedEnumValue.integrationCompleted,
    isProdIntentCompleted,
  ]

  <div className="w-full flex flex-col gap-14">
    {if checkingConditions->Js.Array2.includes(false) {
      <QuickStart isMobileView />
    } else {
      <HomePageOverviewComponent />
    }}
    <RecipesAndPlugins />
    <Resources />
  </div>
}
