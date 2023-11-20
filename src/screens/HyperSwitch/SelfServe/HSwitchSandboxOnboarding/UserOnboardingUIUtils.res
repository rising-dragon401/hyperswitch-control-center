external formEventToStr: ReactEvent.Form.t => string = "%identity"
open UserOnboardingTypes
open UserOnboardingUtils

module ProgressBar = {
  @react.component
  let make = (~tabs, ~tabIndex) => {
    let defaultStyle = currentIndex => {
      currentIndex < tabIndex + 1
        ? "bg-blue-700 h-1.5 w-full"
        : "bg-blue-700 opacity-10 h-1.5 w-full"
    }
    <div className="flex w-full">
      {tabs
      ->Array.mapWithIndex((_val, i) =>
        <div key={string_of_int(i)} className={`${i->defaultStyle}`} />
      )
      ->React.array}
    </div>
  }
}

module PublishableKeyArea = {
  @react.component
  let make = (~currentRoute) => {
    let merchantDetailsValue = HSwitchUtils.useMerchantDetailsValue()
    let detail = merchantDetailsValue->HSwitchMerchantAccountUtils.getMerchantDetails
    let contextName = `${currentRoute->variantToTextMapperForBuildHS}_5.loadhyperswitchcheckout`

    <HelperComponents.KeyAndCopyArea
      copyValue={detail.publishable_key} contextName actionName="publishablekeycopied"
    />
  }
}

module PaymentResponseHashKeyArea = {
  @react.component
  let make = (~currentRoute) => {
    let merchantDetailsValue = HSwitchUtils.useMerchantDetailsValue()
    let detail = merchantDetailsValue->HSwitchMerchantAccountUtils.getMerchantDetails
    let contextName = `${currentRoute->variantToTextMapperForBuildHS}_5.loadhyperswitchcheckout`

    <HelperComponents.KeyAndCopyArea
      copyValue={detail.payment_response_hash_key->Belt.Option.getWithDefault("")}
      contextName
      actionName="paymentresponsehashkeycopied"
    />
  }
}

module DownloadAPIKeyButton = {
  @react.component
  let make = (
    ~buttonText,
    ~currentRoute=OnboardingDefault,
    ~currentTabName="",
    ~buttonStyle="",
  ) => {
    let url = RescriptReactRouter.useUrl()
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let updateDetails = APIUtils.useUpdateMethod(~showErrorToast=false, ())
    let showToast = ToastState.useShowToast()
    let (showCopyToClipboard, setShowCopyToClipboard) = React.useState(_ => false)

    let apiKeyGeneration = async () => {
      try {
        let url = APIUtils.getURL(~entityName=API_KEYS, ~methodType=Post, ())
        let body =
          [
            ("name", "DefaultAPIKey"->Js.Json.string),
            ("description", "Default Value of the API key"->Js.Json.string),
            ("expiration", "never"->Js.Json.string),
          ]->Js.Dict.fromArray
        let res = await updateDetails(url, body->Js.Json.object_, Post)
        let apiKey = res->LogicUtils.getDictFromJsonObject->LogicUtils.getString("api_key", "")
        DownloadUtils.downloadOld(~fileName=`apiKey.txt`, ~content=apiKey)
        Clipboard.writeText(apiKey)
        await HyperSwitchUtils.delay(1000)
        showToast(
          ~message="Api Key has been generated & Copied to clipboard",
          ~toastType=ToastState.ToastSuccess,
          (),
        )
        setShowCopyToClipboard(_ => true)
        await HyperSwitchUtils.delay(2000)
        setShowCopyToClipboard(_ => false)
      } catch {
      | _ => showToast(~message="Api Key Generation Failed", ~toastType=ToastState.ToastError, ())
      }
    }

    let downloadZip = async () => {
      await HyperSwitchUtils.delay(1500)
      showToast(~message="Plugin file has been downloaded!", ~toastType=ToastState.ToastSuccess, ())
    }
    let button =
      <div className="flex items-center gap-5">
        <Button
          text=buttonText
          buttonSize={Medium}
          buttonType={Primary}
          customButtonStyle={`!w-1/3 ${buttonStyle}`}
          rightIcon={FontAwesome("download-api-key")}
          onClick={_ => {
            hyperswitchMixPanel(
              ~pageName=`${url.path->LogicUtils.getListHead}`,
              ~contextName=`${currentRoute->variantToTextMapperForBuildHS}_${currentTabName}`,
              ~actionName="downloadApiKey",
              (),
            )
            switch currentTabName {
            | "downloadWordpressPlugin" => downloadZip()->ignore
            | _ => apiKeyGeneration()->ignore
            }
          }}
        />
        <UIUtils.RenderIf condition=showCopyToClipboard>
          <div className="text-green-700 text-lg"> {"Copied to clipboard"->React.string} </div>
        </UIUtils.RenderIf>
      </div>
    switch currentRoute {
    | WooCommercePlugin =>
      <a href="https://hyperswitch.io/zip/hyperswitch-checkout.zip"> {button} </a>
    | _ => button
    }
  }
}
module DownloadAPIKey = {
  @react.component
  let make = (~currentRoute, ~currentTabName) => {
    <div
      className="bg-white p-7 flex flex-col gap-6 border !shadow-hyperswitch_box_shadow rounded-md">
      <div className="border border-orange-border_orange bg-orange-warning_background_orange p-4">
        <p className="text-base text-orange-warning_text_orange"> {"Warning:"->React.string} </p>
        <p className="text-base">
          {"We request you to store your Test API keys safely. Once lost it cannot be restored; You can re-generate a new key from Dashboard > Developers."->React.string}
        </p>
      </div>
      <DownloadAPIKeyButton buttonText="Download API key" currentRoute currentTabName />
    </div>
  }
}

module DownloadWordPressPlugin = {
  @react.component
  let make = (~currentRoute, ~currentTabName) => {
    <DownloadAPIKeyButton buttonText="Download Plugin" currentRoute currentTabName />
  }
}

module TabsContentWrapper = {
  @react.component
  let make = (~children, ~tabIndex, ~currentRoute, ~customUi=React.null) => {
    let textClass = switch currentRoute {
    | WooCommercePlugin => "text-lg"
    | _ => "text-base"
    }
    <div className="!h-full !w-full py-5 flex flex-col gap-4">
      <div className="flex justify-between w-full items-center">
        <p className={`${textClass} font-medium py-2`}>
          {getContentBasedOnIndex(~currentRoute, ~tabIndex)->React.string}
        </p>
      </div>
      {customUi}
      <div className="border bg-jp-gray-light_gray_bg h-full rounded-md p-6 overflow-scroll">
        {children}
      </div>
    </div>
  }
}
module HeaderCompoentView = {
  @react.component
  let make = (~value, ~headerText, ~langauge: languages, ~currentRoute, ~currentTabName) => {
    let showToast = ToastState.useShowToast()
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let url = RescriptReactRouter.useUrl()
    <div className="flex flex-row justify-between my-4 items-center flex-wrap">
      <p className="text-lg text-grey-700 font-semibold"> {headerText->React.string} </p>
      <div className="flex gap-2">
        <div className="py-1 px-4 border rounded-md flex gap-2 items-center">
          <Icon name={`${(langauge :> string)->Js.String2.toLowerCase}`} size=20 />
          <p className="text-lg text-semibold text-grey-700 opacity-50">
            {(langauge :> string)->React.string}
          </p>
        </div>
        <div
          className="py-1 px-4 border rounded-md flex gap-2 items-center cursor-pointer"
          onClick={_ => {
            Clipboard.writeText(value)
            showToast(~message="Copied to Clipboard!", ~toastType=ToastSuccess, ())
            hyperswitchMixPanel(
              ~pageName=`${url.path->LogicUtils.getListHead}`,
              ~contextName=`${currentRoute->variantToTextMapperForBuildHS}_${currentTabName}`,
              ~actionName=`${(langauge :> string)}_codecopied`,
              (),
            )
          }}>
          <img src={`/assets/CopyToClipboard.svg`} />
          <p className="text-lg text-semibold text-grey-700 opacity-50"> {"Copy"->React.string} </p>
        </div>
      </div>
    </div>
  }
}

module ShowCodeEditor = {
  @react.component
  let make = (
    ~value,
    ~theme,
    ~headerText,
    ~customHeight="8vh",
    ~langauge: languages,
    ~currentRoute,
    ~currentTabName,
  ) => {
    <ReactSuspenseWrapper>
      <MonacoEditorLazy
        defaultLanguage="javascript"
        height=customHeight
        width="w-[90vh]"
        theme
        value
        readOnly=true
        minimap=false
        showCopy=false
        headerComponent={<HeaderCompoentView
          value headerText langauge currentRoute currentTabName
        />}
      />
    </ReactSuspenseWrapper>
  }
}
module DiffCodeEditor = {
  @react.component
  let make = (
    ~valueToShow: migratestripecode,
    ~langauge: languages,
    ~currentRoute,
    ~currentTabName,
  ) => {
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let showToast = ToastState.useShowToast()
    let oldValue = valueToShow.from
    let newValue = valueToShow.to
    let url = RescriptReactRouter.useUrl()
    <div
      className="flex flex-col gap-6 border p-6 bg-white overflow-x-scroll w-full !shadow-hyperswitch_box_shadow rounded-md">
      <div className="flex justify-between">
        <p className="font-semibold text-xl text-grey-700"> {"Replace"->React.string} </p>
        <div className="flex gap-2">
          <div className="py-1 px-4 border rounded-md flex gap-2 items-center">
            <Icon name={`${(langauge :> string)->Js.String2.toLowerCase}`} size=20 />
            <p className="text-lg text-semibold text-grey-700 opacity-50">
              {(langauge :> string)->React.string}
            </p>
          </div>
          <div
            className="py-1 px-4 border rounded-md flex gap-2 items-center cursor-pointer"
            onClick={_ => {
              Clipboard.writeText(newValue)
              showToast(~message="Copied to Clipboard!", ~toastType=ToastSuccess, ())
              hyperswitchMixPanel(
                ~pageName=`${url.path->LogicUtils.getListHead}`,
                ~contextName=`${currentRoute->variantToTextMapperForBuildHS}_${currentTabName}`,
                ~actionName=`${(langauge :> string)}_diffcodecopied`,
                (),
              )
            }}>
            <img src={`/assets/CopyToClipboard.svg`} />
            <p className="text-lg text-semibold text-grey-700 opacity-50">
              {"Copy"->React.string}
            </p>
          </div>
        </div>
      </div>
      <ReactDiffViewer
        oldValue newValue splitView={true} hideLineNumbers={false} useDarkTheme=false
      />
    </div>
  }
}

module BackendFrontendPlatformLangDropDown = {
  @react.component
  let make = (
    ~frontEndLang: languages,
    ~setFrontEndLang,
    ~backEndLang: languages,
    ~setBackEndLang,
    ~isFromLanding=false,
    ~currentRoute,
    ~platform: platforms,
    ~setPlatform,
  ) => {
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let url = RescriptReactRouter.useUrl()
    let urlHead = url.path->LogicUtils.getListHead
    let contextName = `${currentRoute->variantToTextMapperForBuildHS}`
    let platfromInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "Platform Selecr",
      onBlur: _ev => (),
      onChange: ev => {
        let val = ev->formEventToStr->getPlatform
        setPlatform(_ => val)
        hyperswitchMixPanel(~pageName=urlHead, ~contextName, ~actionName={(val :> string)}, ())
      },
      onFocus: _ev => (),
      value: (platform :> string)->Js.Json.string,
      checked: true,
    }
    let options = platforms->Js.Array2.map((op): SelectBox.dropdownOption => {
      {value: (op :> string), label: (op :> string)}
    })

    let backendLangInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "BackEnd",
      onBlur: _ev => (),
      onChange: ev => {
        let val = ev->formEventToStr->getLangauge
        setBackEndLang(_ => val)
        hyperswitchMixPanel(~pageName=urlHead, ~contextName, ~actionName={(val :> string)}, ())
      },
      onFocus: _ev => (),
      value: (backEndLang :> string)->Js.Json.string,
      checked: true,
    }
    let frontendLangInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "FrontEnd",
      onBlur: _ev => (),
      onChange: ev => {
        let val = ev->formEventToStr->getLangauge
        setFrontEndLang(_ => val)
        hyperswitchMixPanel(~pageName=urlHead, ~contextName, ~actionName={(val :> string)}, ())
      },
      onFocus: _ev => (),
      value: (frontEndLang :> string)->Js.Json.string,
      checked: true,
    }
    let (frontendLangauge, backendLangauge) = currentRoute->getLanguages
    let frontendDropdownText = {
      frontEndLang === #ChooseLanguage ? "Choose Frontend" : (frontEndLang :> string)
    }
    let backendDropdownText = {
      backEndLang === #ChooseLanguage ? "Choose Backend" : (backEndLang :> string)
    }

    <Form initialValues={Js.Dict.empty()->Js.Json.object_}>
      <div className="flex flex-row gap-4 flex-wrap">
        <UIUtils.RenderIf condition={!isFromLanding && currentRoute !== SampleProjects}>
          <SelectBox.BaseDropdown
            allowMultiSelect=false
            buttonText="Select Platform"
            input={platfromInput}
            options
            hideMultiSelectButtons=true
            deselectDisable=true
            buttonClickFn={e => {
              hyperswitchMixPanel(
                ~pageName=urlHead,
                ~contextName,
                ~actionName={e->Js.String2.replace(" ", "")},
                (),
              )
            }}
            customButtonStyle="!rounded-md"
            defaultLeftIcon=CustomIcon(<Icon name="show-filters" size=14 />)
            baseComponent={<Button
              text={(platform :> string)}
              buttonSize=Button.Small
              leftIcon=Button.CustomIcon(
                <Icon size=20 name={`${(platform :> string)->Js.String2.toLowerCase}`} />,
              )
              rightIcon=Button.CustomIcon(<Icon className="pl-2 " size=20 name="chevron-down" />)
              ellipsisOnly=true
              customButtonStyle="!bg-white !border !rounded-md"
            />}
          />
        </UIUtils.RenderIf>
        <UIUtils.RenderIf condition={!(requestOnlyPlatforms->Js.Array2.includes(platform))}>
          <SelectBox.BaseDropdown
            allowMultiSelect=false
            buttonText="Select Frontend"
            deselectDisable=true
            input={frontendLangInput}
            options={frontendLangauge->Js.Array2.map((lang): SelectBox.dropdownOption => {
              {value: (lang :> string), label: (lang :> string)}
            })}
            customButtonStyle="!rounded-md"
            buttonClickFn={e => {
              hyperswitchMixPanel(
                ~pageName=urlHead,
                ~contextName,
                ~actionName={e->Js.String2.replace(" ", "")},
                (),
              )
            }}
            hideMultiSelectButtons=true
            autoApply=false
            customStyle="!rounded-md"
            baseComponent={<Button
              text=frontendDropdownText
              buttonSize=Button.Small
              leftIcon=Button.CustomIcon(
                <Icon size=20 name={`${(frontEndLang :> string)->Js.String2.toLowerCase}`} />,
              )
              rightIcon=Button.CustomIcon(<Icon className="pl-2 " size=20 name="chevron-down" />)
              ellipsisOnly=true
              customButtonStyle="!bg-white !border !rounded-md"
            />}
          />
          <SelectBox.BaseDropdown
            allowMultiSelect=false
            buttonText="Select Backend"
            input={backendLangInput}
            deselectDisable=true
            buttonClickFn={e => {
              hyperswitchMixPanel(
                ~pageName=urlHead,
                ~contextName,
                ~actionName={e->Js.String2.replace(" ", "")},
                (),
              )
            }}
            customButtonStyle="!rounded-md"
            options={backendLangauge->Js.Array2.map((lang): SelectBox.dropdownOption => {
              {value: (lang :> string), label: (lang :> string)}
            })}
            hideMultiSelectButtons=true
            baseComponent={<Button
              text=backendDropdownText
              buttonSize=Button.Small
              leftIcon=Button.CustomIcon(
                <Icon size=20 name={`${(backEndLang :> string)->Js.String2.toLowerCase}`} />,
              )
              rightIcon=Button.CustomIcon(<Icon className="pl-2 " size=20 name="chevron-down" />)
              ellipsisOnly=true
              customButtonStyle="!bg-white !border !rounded-md"
            />}
          />
        </UIUtils.RenderIf>
      </div>
    </Form>
  }
}

module LanguageTag = {
  @react.component
  let make = (~frontendLang="", ~backendLang="") => {
    <UIUtils.RenderIf
      condition={frontendLang->Js.String2.length > 0 && backendLang->Js.String2.length > 0}>
      <div className="flex gap-2 items-center">
        <Icon name={`${frontendLang}`} size=25 />
        <Icon name={`${backendLang}`} size=25 />
      </div>
    </UIUtils.RenderIf>
  }
}

let headerTextCss = "font-semibold text-grey-700 text-xl"
let subTextCss = "font-normal text-grey-700 opacity-50 text-base"
module LandingPageTileForIntegrateDocs = {
  @react.component
  let make = (
    ~headerIcon,
    ~headerText,
    ~subText,
    ~buttonText,
    ~customIconCss,
    ~url,
    ~isIconImg,
    ~imagePath,
    ~leftSection,
    ~isFromOnboardingChecklist,
    ~subTextCustomValues,
    ~buttonType: Button.buttonType=Secondary,
    ~isSkipButton=false,
    ~isTileVisible=true,
    ~rightIcon,
    ~customRedirection=?,
  ) => {
    open APIUtils
    let urlPath = RescriptReactRouter.useUrl()
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let updateDetails = useUpdateMethod(~showErrorToast=false, ())
    let filtersFromUrl =
      LogicUtils.getDictFromUrlSearchParams(urlPath.search)
      ->Js.Dict.get("type")
      ->Belt.Option.getWithDefault("")
    let {
      integrationDetails,
      setIntegrationDetails,
      dashboardPageState,
      setDashboardPageState,
    } = React.useContext(GlobalProvider.defaultContext)
    let redirect = () => {
      if customRedirection->Belt.Option.isSome {
        RescriptReactRouter.replace(
          `${HSwitchGlobalVars.hyperSwitchFEPrefix}/${customRedirection->Belt.Option.getWithDefault(
              "",
            )}?type=${url}`,
        )
      } else {
        RescriptReactRouter.replace(
          `${HSwitchGlobalVars.hyperSwitchFEPrefix}/onboarding?type=${url}`,
        )
      }
      hyperswitchMixPanel(
        ~pageName=`${urlPath.path->LogicUtils.getListHead}`,
        ~contextName=headerText->LogicUtils.toCamelCase,
        ~actionName=buttonText->LogicUtils.toCamelCase,
        (),
      )
    }
    let skipAndContinue = async () => {
      getMixPanelEventName(~url=urlPath, ~filtersFromUrl, ~hyperswitchMixPanel)
      try {
        let url = getURL(~entityName=INTEGRATION_DETAILS, ~methodType=Post, ())
        let metaDataDict = Js.Dict.fromArray([("is_skip", true->Js.Json.boolean)])->Js.Json.object_
        let body = HSwitchUtils.constructOnboardingBody(
          ~dashboardPageState,
          ~integrationDetails,
          ~is_done=false,
          ~metadata=metaDataDict,
          (),
        )
        let _res = await updateDetails(url, body, Post)
        setIntegrationDetails(_ => body->ProviderHelper.getIntegrationDetails)
      } catch {
      | _ => ()
      }
      setDashboardPageState(_ => #HOME)
    }
    <UIUtils.RenderIf condition={!isFromOnboardingChecklist || isTileVisible}>
      <div
        className="p-8 border rounded-md flex flex-col gap-7 justify-between bg-white w-full md:w-1/3">
        <div className="flex justify-between flex-wrap">
          {if isIconImg {
            <div className="w-30 h-8">
              <img src=imagePath />
            </div>
          } else {
            <Icon size=35 name=headerIcon className=customIconCss />
          }}
          <UIUtils.RenderIf condition={rightIcon->Belt.Option.isSome}>
            {rightIcon->Belt.Option.getWithDefault(React.null)}
          </UIUtils.RenderIf>
          {leftSection}
        </div>
        <div className="flex flex-col gap-2">
          <p className=headerTextCss> {headerText->React.string} </p>
          <UIUtils.RenderIf condition={subText->Belt.Option.isSome}>
            <p className=subTextCss> {subText->Belt.Option.getWithDefault("")->React.string} </p>
          </UIUtils.RenderIf>
          <div>
            <UIUtils.RenderIf condition={subTextCustomValues->Belt.Option.isSome}>
              <div className={`flex flex-col gap-3 mt-4`}>
                {subTextCustomValues
                ->Belt.Option.getWithDefault([])
                ->Array.mapWithIndex((val, index) => {
                  <div key={index->string_of_int} className=subTextCss> {val->React.string} </div>
                })
                ->React.array}
              </div>
            </UIUtils.RenderIf>
          </div>
        </div>
        <Button
          text=buttonText
          buttonType
          onClick={_ => isSkipButton ? skipAndContinue()->ignore : redirect()}
        />
      </div>
    </UIUtils.RenderIf>
  }
}

module LandingPageTileForGithub = {
  @react.component
  let make = (~headerIcon, ~customIconCss, ~url, ~displayFrontendLang, ~displayBackendLang) => {
    let urlPath = RescriptReactRouter.useUrl()
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let redirect = () => {
      Window._open(url)
      hyperswitchMixPanel(
        ~pageName=`${urlPath.path->LogicUtils.getListHead}`,
        ~contextName=`${displayFrontendLang->Js.String2.replace("-", "")}_${displayBackendLang}`,
        ~actionName="open_in_new_tab",
        (),
      )
    }
    <div
      className={`p-5 border rounded-md flex flex-col gap-4 justify-between bg-white cursor-pointer hover:bg-jp-gray-light_gray_bg`}
      onClick={_ => redirect()}>
      <div>
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <p className=headerTextCss> {displayFrontendLang->React.string} </p>
            <Icon name="small-dot" />
            <p className=headerTextCss> {displayBackendLang->React.string} </p>
          </div>
          <Icon name="open-new-tab" customIconColor="black" />
        </div>
      </div>
      <div className="flex items-center gap-3">
        <Icon size=20 name=headerIcon className=customIconCss />
        <div className="text-md text-grey-600"> {"Web"->React.string} </div>
      </div>
    </div>
  }
}
module Section = {
  @react.component
  let make = (
    ~sectionHeaderText,
    ~sectionSubText,
    ~subSectionArray: array<UserOnboardingTypes.sectionContentType>,
    ~leftSection=<> </>,
    ~isFromOnboardingChecklist=false,
    ~isGithubSection=false,
    ~customRedirection=?,
  ) => {
    <div className="flex flex-col gap-6">
      <div className="flex justify-between items-center flex-wrap">
        <div className="flex flex-col gap-1">
          <p className=headerTextCss> {sectionHeaderText->React.string} </p>
          <p className=subTextCss> {sectionSubText->React.string} </p>
        </div>
        {leftSection}
      </div>
      <div
        className={` ${isGithubSection
            ? "grid grid-cols-1 md:grid-cols-3"
            : "flex md:flex-row flex-col items-center flex-wrap gap-16"} gap-6`}>
        {subSectionArray
        ->Array.mapWithIndex((subSectionValue, index) => {
          isGithubSection
            ? <LandingPageTileForGithub
                key={index->string_of_int}
                headerIcon=subSectionValue.headerIcon
                customIconCss=subSectionValue.customIconCss
                url=subSectionValue.url
                displayFrontendLang={subSectionValue.displayFrontendLang->Belt.Option.getWithDefault(
                  "",
                )}
                displayBackendLang={subSectionValue.displayBackendLang->Belt.Option.getWithDefault(
                  "",
                )}
              />
            : <LandingPageTileForIntegrateDocs
                key={index->string_of_int}
                headerIcon=subSectionValue.headerIcon
                headerText={subSectionValue.headerText->Belt.Option.getWithDefault("")}
                subText=subSectionValue.subText
                buttonText=subSectionValue.buttonText
                customIconCss=subSectionValue.customIconCss
                url=subSectionValue.url
                isIconImg={subSectionValue.isIconImg->Belt.Option.getWithDefault(false)}
                imagePath={subSectionValue.imagePath->Belt.Option.getWithDefault("")}
                leftSection={<LanguageTag
                  frontendLang={subSectionValue.frontEndLang->Belt.Option.getWithDefault("")}
                  backendLang={subSectionValue.backEndLang->Belt.Option.getWithDefault("")}
                />}
                isFromOnboardingChecklist
                subTextCustomValues=subSectionValue.subTextCustomValues
                buttonType={subSectionValue.buttonType->Belt.Option.getWithDefault(Secondary)}
                isSkipButton={subSectionValue.isSkipButton->Belt.Option.getWithDefault(false)}
                isTileVisible={subSectionValue.isTileVisible->Belt.Option.getWithDefault(true)}
                rightIcon={subSectionValue.rightIcon}
                customRedirection={customRedirection->Belt.Option.getWithDefault("")}
              />
        })
        ->React.array}
      </div>
    </div>
  }
}

let getTabsForIntegration = (
  ~currentRoute,
  ~tabIndex,
  ~frontEndLang,
  ~theme,
  ~backEndLang,
  ~publishablekeyMerchant,
) => {
  open Tabs
  let defaultEditorStyle = "flex flex-col gap-8 bg-white flex flex-col px-6 py-4 border !shadow-hyperswitch_box_shadow rounded-md"
  let updateDetails = APIUtils.useUpdateMethod(~showErrorToast=false, ())
  let urlPath = RescriptReactRouter.useUrl()
  let filtersFromUrl =
    LogicUtils.getDictFromUrlSearchParams(urlPath.search)
    ->Js.Dict.get("type")
    ->Belt.Option.getWithDefault("")
  let hyperswitchMixPanel = HSMixPanel.useSendEvent()
  let {integrationDetails, setIntegrationDetails, dashboardPageState} = React.useContext(
    GlobalProvider.defaultContext,
  )
  switch currentRoute {
  | MigrateFromStripe => [
      {
        title: "1. Download API Key",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <DownloadAPIKey currentRoute currentTabName="downloadApiKey" />
          </TabsContentWrapper>,
      },
      {
        title: "2. Install Dependencies",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <div className=defaultEditorStyle>
              <ShowCodeEditor
                value={frontEndLang->getMigrateFromStripeDX(backEndLang)}
                theme
                headerText="Installation"
                langauge=backEndLang
                currentRoute
                currentTabName="2.installdependencies"
              />
            </div>
          </TabsContentWrapper>,
      },
      {
        title: "3. Replace API Key",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <DiffCodeEditor
              valueToShow={backEndLang->getReplaceAPIkeys}
              langauge=backEndLang
              currentRoute
              currentTabName="3.replaceaPIkey"
            />
          </TabsContentWrapper>,
      },
      {
        title: "4. Reconfigure Checkout Form",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex customUi={<PublishableKeyArea currentRoute />}>
            <DiffCodeEditor
              valueToShow={frontEndLang->getCheckoutForm}
              langauge=frontEndLang
              currentRoute
              currentTabName="4.reconfigurecheckoutform"
            />
          </TabsContentWrapper>,
      },
      {
        title: "5. Load HyperSwitch Checkout",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex customUi={<PublishableKeyArea currentRoute />}>
            <DiffCodeEditor
              valueToShow={frontEndLang->getHyperswitchCheckout}
              langauge=frontEndLang
              currentRoute
              currentTabName="5.loadhyperSwitchcheckout"
            />
          </TabsContentWrapper>,
      },
    ]
  | IntegrateFromScratch => [
      {
        title: "1. Download API Key",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <DownloadAPIKey currentRoute currentTabName="downloadApiKey" />
          </TabsContentWrapper>,
      },
      {
        title: "2. Create a Payment",
        renderContent: () =>
          <TabsContentWrapper
            currentRoute
            tabIndex
            customUi={<p className="text-base font-normal py-2 flex gap-2">
              {"For the complete API schema, refer "->React.string}
              <p
                className="text-blue-700 underline cursor-pointer"
                onClick={_ =>
                  Window._open(
                    "https://api-reference.hyperswitch.io/docs/hyperswitch-api-reference/60bae82472db8-payments-create",
                  )}>
                {"API docs"->React.string}
              </p>
            </p>}>
            <div className=defaultEditorStyle>
              <UIUtils.RenderIf
                condition={backEndLang->getInstallDependencies->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={backEndLang->getInstallDependencies}
                  theme
                  headerText="Installation"
                  langauge=backEndLang
                  currentRoute
                  currentTabName="2.createapayment"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <ShowCodeEditor
                value={backEndLang->getCreateAPayment}
                theme
                headerText="Request"
                customHeight="25vh"
                langauge=backEndLang
                currentRoute
                currentTabName="2.createapayment"
              />
            </div>
          </TabsContentWrapper>,
      },
      {
        title: "3. Display Checkout Page",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex customUi={<PublishableKeyArea currentRoute />}>
            <div className=defaultEditorStyle>
              <UIUtils.RenderIf
                condition={frontEndLang->getInstallDependencies->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getInstallDependencies}
                  theme
                  headerText="Installation"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="3.displaycheckoutpage"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <UIUtils.RenderIf
                condition={frontEndLang->getInstallDependencies->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getImports}
                  theme
                  headerText="Imports"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="3.displaycheckoutpage"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <UIUtils.RenderIf condition={frontEndLang->getLoad->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getLoad}
                  theme
                  headerText="Load"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="3.displaycheckoutpage"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <UIUtils.RenderIf condition={frontEndLang->getInitialize->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getInitialize}
                  theme
                  headerText="Initialize"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="3.displaycheckoutpage"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <UIUtils.RenderIf
                condition={frontEndLang
                ->getCheckoutFormForDisplayCheckoutPage
                ->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getCheckoutFormForDisplayCheckoutPage}
                  theme
                  headerText="Checkout Form"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="3.displaycheckoutpage"
                />
              </UIUtils.RenderIf>
            </div>
          </TabsContentWrapper>,
      },
      {
        title: "4. Display Payment Confirmation",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex customUi={<PublishableKeyArea currentRoute />}>
            <div className=defaultEditorStyle>
              <UIUtils.RenderIf condition={frontEndLang->getHandleEvents->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getHandleEvents}
                  theme
                  headerText="Handle Events"
                  customHeight="20vh"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="4.displaypaymentconfirmation"
                />
                <div className="w-full h-px bg-jp-gray-700" />
              </UIUtils.RenderIf>
              <UIUtils.RenderIf
                condition={frontEndLang->getDisplayConformation->Js.String2.length > 0}>
                <ShowCodeEditor
                  value={frontEndLang->getDisplayConformation}
                  theme
                  headerText="Display Payment Confirmation"
                  customHeight="20vh"
                  langauge=frontEndLang
                  currentRoute
                  currentTabName="4.displaypaymentconfirmation"
                />
              </UIUtils.RenderIf>
            </div>
          </TabsContentWrapper>,
      },
    ]

  | SampleProjects => [
      {
        title: "1. Download API Key",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <DownloadAPIKey currentRoute currentTabName="1.downloadaPIkey" />
          </TabsContentWrapper>,
      },
      {
        title: "2. Explore Sample Project",
        renderContent: () =>
          <TabsContentWrapper
            currentRoute
            tabIndex
            customUi={<p className="text-base font-normal py-2 flex gap-2">
              {"Explore Sample Projects, make use of the publishable key wherever needed "->React.string}
            </p>}>
            <div className="flex flex-col gap-5">
              <div className=defaultEditorStyle>
                <HelperComponents.KeyAndCopyArea
                  copyValue=publishablekeyMerchant
                  contextName="setup_webhook_processor"
                  actionName="hs_webhookcopied"
                  shadowClass="shadow shadow-hyperswitch_box_shadow md:!w-max"
                />
              </div>
              <div className=defaultEditorStyle>
                <Section
                  sectionHeaderText="Clone a sample project"
                  sectionSubText="Try out your choice of integration by cloning sample project"
                  subSectionArray={getFilteredList(frontEndLang, backEndLang, githubCodespaces)}
                  isGithubSection=true
                />
              </div>
            </div>
          </TabsContentWrapper>,
      },
    ]

  | WooCommercePlugin => [
      {
        title: "1. Connect",
        renderContent: () =>
          <TabsContentWrapper currentRoute tabIndex>
            <div
              className="bg-white p-7 flex flex-col gap-6 border !shadow-hyperswitch_box_shadow rounded-md">
              <DownloadWordPressPlugin currentRoute currentTabName="downloadWordpressPlugin" />
            </div>
          </TabsContentWrapper>,
      },
      {
        title: "2. Configure",
        renderContent: () =>
          <div>
            <TabsContentWrapper currentRoute tabIndex={1}>
              <div
                className="bg-white p-7 flex flex-col gap-6 border !shadow-hyperswitch_box_shadow rounded-md">
                <img
                  style={ReactDOMStyle.make(
                    ~height="400px",
                    ~width="100%",
                    ~objectFit="cover",
                    ~objectPosition="0% 12%",
                    (),
                  )}
                  src="https://hyperswitch.io/img/site/wordpress_hyperswitch_settings.png"
                />
              </div>
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex={2}>
              <DownloadAPIKey currentRoute currentTabName="downloadApiKey" />
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex={3}>
              <PublishableKeyArea currentRoute />
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex={4}>
              <PaymentResponseHashKeyArea currentRoute />
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex={5}>
              <div
                className="bg-white p-7 flex flex-col gap-6 border !shadow-hyperswitch_box_shadow rounded-md">
                <img
                  style={ReactDOMStyle.make(
                    ~height="120px",
                    ~width="100%",
                    ~objectFit="cover",
                    ~objectPosition="0% 52%",
                    (),
                  )}
                  src="https://hyperswitch.io/img/site/wordpress_hyperswitch_settings.png"
                />
              </div>
              <Webhooks webhookOnly=true />
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex={6}>
              <div
                className="bg-white p-7 flex flex-col gap-6 border !shadow-hyperswitch_box_shadow rounded-md">
                <img
                  style={ReactDOMStyle.make(
                    ~height="120px",
                    ~width="100%",
                    ~objectFit="cover",
                    ~objectPosition="0% 100%",
                    (),
                  )}
                  src="https://hyperswitch.io/img/site/wordpress_hyperswitch_settings.png"
                />
              </div>
            </TabsContentWrapper>
            <div className="mt-4">
              {React.string(
                "Additionally, you can configure the other settings such as appearance, layout, etc as per your requirements.",
              )}
            </div>
          </div>,
      },
      {
        title: "3. Manage",
        renderContent: () => {
          let skipAndContinue = async () => {
            UserOnboardingUtils.getMixPanelEventName(
              ~url=urlPath,
              ~filtersFromUrl,
              ~hyperswitchMixPanel,
            )
            try {
              let url = APIUtils.getURL(~entityName=INTEGRATION_DETAILS, ~methodType=Post, ())
              let metaDataDict =
                Js.Dict.fromArray([("is_skip", true->Js.Json.boolean)])->Js.Json.object_
              let body = HSwitchUtils.constructOnboardingBody(
                ~dashboardPageState,
                ~integrationDetails,
                ~is_done=false,
                ~metadata=metaDataDict,
                (),
              )
              let _res = await updateDetails(url, body, Post)
              setIntegrationDetails(_ => body->ProviderHelper.getIntegrationDetails)
            } catch {
            | _ => ()
            }
          }
          let skipOnboarding = async path => {
            let _skipOnboarding = await skipAndContinue()
            Window._open(path)
          }
          <div>
            <TabsContentWrapper currentRoute tabIndex=7>
              <div onClick={_ => skipOnboarding(`/connectors`)->ignore} className="cursor-pointer">
                <div className="pointer-events-none">
                  <ConnectorList.NewProcessorCards
                    configuredConnectors=[] showIcons=true isPayoutFlow=false
                  />
                </div>
              </div>
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex=8>
              <div onClick={_ => skipOnboarding(`/routing`)->ignore} className="cursor-pointer">
                <div className="pointer-events-none">
                  <RoutingStack remainingPath={list{}} previewOnly=true />
                </div>
              </div>
            </TabsContentWrapper>
            <TabsContentWrapper currentRoute tabIndex=9>
              <div onClick={_ => skipOnboarding(`/payments`)->ignore} className="cursor-pointer">
                <div className="pointer-events-none overflow-hidden">
                  <Orders previewOnly=true />
                </div>
              </div>
            </TabsContentWrapper>
            // <MilestoneAchievedCard
            //   headingModule="WooCommerce integration!"
            //   subText="Test your integration by placing an order and completing a payment on your store!"
            //   customBackButtonRoute=""
            // />
          </div>
        },
      },
    ]
  | _ => []
  }
}

module GitHubLanguageFilters = {
  @react.component
  let make = (
    ~frontEndLang: languages,
    ~setFrontEndLang,
    ~backEndLang: languages,
    ~setBackEndLang,
    ~isFromOnboardingChecklist=false,
  ) => {
    let hyperswitchMixPanel = HSMixPanel.useSendEvent()
    let url = RescriptReactRouter.useUrl()
    let urlHead = url.path->LogicUtils.getListHead

    let backendLangInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "Backend",
      onBlur: _ev => (),
      onChange: ev => {
        let val = ev->formEventToStr->getLangauge
        setBackEndLang(_ => val)
        hyperswitchMixPanel(~eventName=Some(`${urlHead}_${(val :> string)}`), ())
      },
      onFocus: _ev => (),
      value: (backEndLang :> string)->Js.Json.string,
      checked: true,
    }
    let frontendLangInput: ReactFinalForm.fieldRenderPropsInput = {
      name: "Frontend",
      onBlur: _ev => (),
      onChange: ev => {
        let val = ev->formEventToStr->getLangauge
        setFrontEndLang(_ => val)
        hyperswitchMixPanel(~eventName=Some(`${urlHead}_${(val :> string)}`), ())
      },
      onFocus: _ev => (),
      value: (frontEndLang :> string)->Js.Json.string,
      checked: true,
    }

    let frontendDropdownText = {
      frontEndLang === #ChooseLanguage ? "Choose Frontend" : (frontEndLang :> string)
    }
    let backendDropdownText = {
      backEndLang === #ChooseLanguage ? "Choose Backend" : (backEndLang :> string)
    }

    <Form initialValues={Js.Dict.empty()->Js.Json.object_}>
      <div className="flex flex-row gap-4 flex-wrap">
        <SelectBox.BaseDropdown
          allowMultiSelect=false
          buttonText="Select Frontend"
          input={frontendLangInput}
          options={frontendLangForGithub->Js.Array2.map((lang): SelectBox.dropdownOption => {
            {value: (lang :> string), label: (lang :> string)}
          })}
          customButtonStyle="!rounded-md"
          hideMultiSelectButtons=true
          buttonClickFn={e => {
            hyperswitchMixPanel(~eventName=Some(`${urlHead}_${e->Js.String2.replace(" ", "")}`), ())
          }}
          autoApply=false
          customStyle="!rounded-md"
          baseComponent={<Button
            text=frontendDropdownText
            buttonSize=Button.Small
            leftIcon={Button.CustomIcon(
              frontEndLang === #ChooseLanguage
                ? React.null
                : <Icon size=20 name={`${(frontEndLang :> string)->Js.String2.toLowerCase}`} />,
            )}
            rightIcon=Button.CustomIcon(<Icon className="pl-2" size=20 name="chevron-down" />)
            ellipsisOnly=true
            customButtonStyle="!bg-white !border !rounded-md !py-2 !px-4"
          />}
        />
        <SelectBox.BaseDropdown
          allowMultiSelect=false
          dropdownCustomWidth="w-full md:max-w-md min-w-[5rem]"
          buttonText="Select Backend"
          input={backendLangInput}
          customButtonStyle="!rounded-md"
          options={backendLangForGithub->Js.Array2.map((lang): SelectBox.dropdownOption => {
            {value: (lang :> string), label: (lang :> string)}
          })}
          hideMultiSelectButtons=true
          buttonClickFn={e => {
            hyperswitchMixPanel(~eventName=Some(`${urlHead}_${e->Js.String2.replace(" ", "")}`), ())
          }}
          baseComponent={<Button
            text=backendDropdownText
            buttonSize=Button.Small
            leftIcon={Button.CustomIcon(
              frontEndLang === #ChooseLanguage
                ? React.null
                : <Icon size=20 name={`${(backEndLang :> string)->Js.String2.toLowerCase}`} />,
            )}
            rightIcon=Button.CustomIcon(<Icon className="pl-2" size=20 name="chevron-down" />)
            ellipsisOnly=true
            customButtonStyle="!bg-white !border !rounded-md !py-2 !px-4"
          />}
        />
      </div>
    </Form>
  }
}
