@react.component
let make = (~setAuthStatus: HyperSwitchAuthTypes.authStatus => unit, ~authType, ~setAuthType) => {
  open HyperSwitchAuthUtils
  open APIUtils
  open HSwitchUtils
  open HyperSwitchAuthForm
  open HSwitchGlobalVars
  open LogicUtils

  let url = RescriptReactRouter.useUrl()
  let initialValues = Js.Dict.empty()->Js.Json.object_
  let clientCountry = HSwitchUtils.getBrowswerDetails().clientCountry
  let country = clientCountry.isoAlpha2->CountryUtils.getCountryCodeStringFromVarient
  let hyperswitchMixPanel = HSMixPanel.useSendEvent()
  let showToast = ToastState.useShowToast()
  let updateDetails = useUpdateMethod(~showErrorToast=false, ())
  let (email, setEmail) = React.useState(_ => "")
  let {magicLink: isMagicLinkEnabled} =
    HyperswitchAtom.featureFlagAtom
    ->Recoil.useRecoilValueFromAtom
    ->LogicUtils.safeParse
    ->FeatureFlagUtils.featureFlagType

  let handleAuthError = e => {
    let error = e->parseErrorMessage
    switch error.code->errorSubCodeMapper {
    | UR_03 => "An account already exists with this email"
    | UR_05 => {
        setAuthType(_ => HyperSwitchAuthTypes.ResendVerifyEmail)
        "Kindly verify your account"
      }
    | UR_16 => "Please use a valid email"
    | UR_01 => "Incorrect email or password"
    | _ => "Register failed, Try again"
    }
  }

  let getUserWithEmail = async body => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#SIGNIN, ~methodType=Post, ())
      let res = await updateDetails(url, body, Post)
      let valuesDict = res->getDictFromJsonObject
      let magicLinkSent = valuesDict->LogicUtils.getBool("is_email_sent", false)

      if magicLinkSent {
        setAuthType(_ => MagicLinkEmailSent)
      } else {
        showToast(~message="Failed to send an email, Try again", ~toastType=ToastError, ())
      }
    } catch {
    | Js.Exn.Error(e) => showToast(~message={e->handleAuthError}, ~toastType=ToastError, ())
    }
    Js.Nullable.null
  }

  let getUserWithEmailPassword = async (body, email) => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#SIGNIN, ~methodType=Post, ())
      let res = await updateDetails(url, body, Post)
      let token = parseResponseJson(~json=res, ~email)

      // home
      if !(token->HSwitchUtils.isEmptyString) {
        let token = parseResponseJson(~json=res, ~email)
        setAuthStatus(LoggedIn(HyperSwitchAuthTypes.getDummyAuthInfoForToken(token)))
      } else {
        showToast(~message="Failed to sign in, Try again", ~toastType=ToastError, ())
        setAuthStatus(LoggedOut)
      }
    } catch {
    | Js.Exn.Error(e) => showToast(~message={e->handleAuthError}, ~toastType=ToastError, ())
    }
    Js.Nullable.null
  }

  let openPlayground = _ => {
    hyperswitchMixPanel(~eventName=Some("try_playground"), ~email=playgroundUserEmail, ())
    let body = getEmailPasswordBody(playgroundUserEmail, playgroundUserPassword, country)
    getUserWithEmailPassword(body, playgroundUserEmail)->ignore
    HSLocalStorage.setIsPlaygroundInLocalStorage(true)
  }

  let setResetPassword = async body => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#RESET_PASSWORD, ~methodType=Post, ())
      let _res = await updateDetails(url, body, Post)
      RescriptReactRouter.push("/")
      showToast(~message=`Password Changed Successfully`, ~toastType=ToastSuccess, ())
      setAuthType(_ => LoginWithEmail)
      Window.Location.reload()
    } catch {
    | _ => showToast(~message="Password Reset Failed, Try again", ~toastType=ToastError, ())
    }
    Js.Nullable.null
  }

  let setForgetPassword = async body => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#FORGOT_PASSWORD, ~methodType=Post, ())
      let _res = await updateDetails(url, body, Post)
      setAuthType(_ => ForgetPasswordEmailSent)
      showToast(~message="Please check your registered e-mail", ~toastType=ToastSuccess, ())
    } catch {
    | _ => showToast(~message="Forgot Password Failed, Try again", ~toastType=ToastError, ())
    }
    Js.Nullable.null
  }

  let resendVerifyEmail = async body => {
    try {
      let url = getURL(~entityName=USERS, ~userType=#VERIFY_EMAIL_REQUEST, ~methodType=Post, ())
      let _res = await updateDetails(url, body, Post)
      setAuthType(_ => ResendVerifyEmailSent)
      showToast(~message="Please check your registered e-mail", ~toastType=ToastSuccess, ())
    } catch {
    | _ => showToast(~message="Resend mail failed, Try again", ~toastType=ToastError, ())
    }
    Js.Nullable.null
  }

  let logMixpanelEvents = email => {
    open HyperSwitchAuthTypes
    switch authType {
    | LoginWithPassword => hyperswitchMixPanel(~eventName=Some("landing_loginbutton"), ~email, ())
    | LoginWithEmail =>
      hyperswitchMixPanel(~eventName=Some("landing_loginbutton_magic_link"), ~email, ())
    | SignUP => hyperswitchMixPanel(~eventName=Some("landing_registerbutton"), ~email, ())
    | MagicLinkEmailSent => hyperswitchMixPanel(~eventName=Some("landing_verifyemail"), ~email, ())
    | EmailVerify => hyperswitchMixPanel(~eventName=Some("landing_emailverify"), ~email, ())
    | ForgetPassword => hyperswitchMixPanel(~eventName=Some("landing_forgotpassword"), ~email, ())
    | ForgetPasswordEmailSent =>
      hyperswitchMixPanel(~eventName=Some("landing_forgetpassword_resend_mail"), ~email, ())
    | MagicLinkVerify => hyperswitchMixPanel(~eventName=Some("landing_magiclinkverify"), ~email, ())
    | ResendVerifyEmail =>
      hyperswitchMixPanel(~eventName=Some("landing_resendverifyemail"), ~email, ())
    | ResendVerifyEmailSent =>
      hyperswitchMixPanel(~eventName=Some("landing_verifyemail_resend_mail"), ~email, ())
    | ResetPassword => hyperswitchMixPanel(~eventName=Some("landing_resetpassword"), ~email, ())
    | LiveMode => hyperswitchMixPanel(~eventName=Some("landing_livetesttoggle"), ~email, ())
    }
  }

  let onSubmit = (values, _) => {
    open Promise

    let valuesDict = values->getDictFromJsonObject
    let email = valuesDict->getString("email", "")
    setEmail(_ => email)
    logMixpanelEvents(email)

    switch (isMagicLinkEnabled, authType) {
    | (true, SignUP) | (true, LoginWithEmail) => {
        let body = getEmailBody(email, ~country, ())

        getUserWithEmail(body)
      }
    | (true, ForgetPassword) =>
      let body = email->getEmailBody()

      setForgetPassword(body)

    | (true, ResendVerifyEmail) =>
      let body = email->getEmailBody()
      resendVerifyEmail(body)

    | (false, SignUP) => {
        let password = getString(valuesDict, "password", "")
        let body = getEmailPasswordBody(email, password, country)

        getUserWithEmailPassword(body, email)
      }
    | (_, LoginWithPassword) => {
        let password = getString(valuesDict, "password", "")
        let body = getEmailPasswordBody(email, password, country)

        getUserWithEmailPassword(body, email)
      }
    | (_, ResetPassword) => {
        let queryDict = url.search->getDictFromUrlSearchParams
        let password_reset_token = queryDict->Js.Dict.get("token")->Belt.Option.getWithDefault("")
        let password = getString(valuesDict, "create_password", "")
        let body = getResetpasswordBodyJson(password, password_reset_token)
        setResetPassword(body)
      }

    | _ => Js.Nullable.null->resolve
    }
  }

  let resendEmail = () => {
    let body = email->getEmailBody()
    switch authType {
    | MagicLinkEmailSent => getUserWithEmail(body)->ignore
    | ForgetPasswordEmailSent => setForgetPassword(body)->ignore
    | ResendVerifyEmailSent => resendVerifyEmail(body)->ignore
    | _ => ()
    }
  }

  let submitBtnText = switch authType {
  | LoginWithPassword | LoginWithEmail => "Continue"
  | ResetPassword => "Confirm"
  | ForgetPassword => "Reset password"
  | ResendVerifyEmail => "Send mail"
  | _ => "Get started, for free!"
  }

  let validateKeys = switch authType {
  | ForgetPassword
  | ResendVerifyEmail
  | SignUP
  | LoginWithEmail => ["email"]
  | LoginWithPassword => ["email", "password"]
  | ResetPassword => ["create_password", "comfirm_password"]
  | _ => []
  }

  React.useEffect0(() => {
    if url.hash === "playground" {
      openPlayground()
    }
    None
  })

  <ReactFinalForm.Form
    key="auth"
    initialValues
    subscription=ReactFinalForm.subscribeToValues
    validate={values => validateForm(values, validateKeys)}
    onSubmit
    render={({handleSubmit}) => {
      <>
        <Header authType setAuthType email />
        <form
          onSubmit={handleSubmit}
          className={`flex flex-col justify-evenly gap-5 h-full w-full !overflow-visible text-grey-600`}>
          {switch authType {
          | LoginWithPassword => <EmailPasswordForm setAuthType isMagicLinkEnabled />
          | LoginWithEmail
          | ForgetPassword
          | ResendVerifyEmail
          | SignUP =>
            isMagicLinkEnabled
              ? <EmailForm />
              : <EmailPasswordForm setAuthType isMagicLinkEnabled />
          | ResetPassword => <ResetPasswordForm />
          | MagicLinkEmailSent | ForgetPasswordEmailSent | ResendVerifyEmailSent =>
            <ResendBtn callBackFun={resendEmail} />
          | _ => React.null
          }}
          <div className="flex flex-col gap-2">
            {switch authType {
            | LoginWithPassword
            | LoginWithEmail
            | ResetPassword
            | ForgetPassword
            | ResendVerifyEmail
            | SignUP =>
              <FormRenderer.SubmitButton
                customSumbitButtonStyle="!w-full !rounded"
                text=submitBtnText
                userInteractionRequired=true
                showToolTip=false
                loadingText="Please wait..."
              />
            | _ => React.null
            }}
          </div>
          <div className="text-center text-sm">
            {"By continuing, you agree to our "->React.string}
            <a
              className="font-medium text-grey-900"
              href="https://hyperswitch.io/terms-of-services"
              target="__blank">
              {"Terms of Service "->React.string}
            </a>
            {" & "->React.string}
            <a
              className="font-medium text-grey-900"
              href="https://hyperswitch.io/privacyPolicy"
              target="__blank">
              {"Privacy Policy"->React.string}
            </a>
          </div>
        </form>
      </>
    }}
  />
}
