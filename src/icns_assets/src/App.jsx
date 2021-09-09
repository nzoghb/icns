import React, { Fragment, useContext, useEffect, useState, lazy } from "react";
import { BrowserRouter, Route as DefaultRoute, Switch } from "react-router-dom";
import { Error404 } from "./components/Error.jsx";
// import DefaultLayout from "./layout/DefaultLayout";
import Home from "./routes/Home";

const HomePageLayout = ({ children }) => <Fragment>{children}</Fragment>;

// const Route = ({
//   component: Component,
//   layout: Layout = DefaultLayout,
//   ...rest
// }) => {
//   pageview();
//   return (
//     <DefaultRoute
//       {...rest}
//       render={(props) => (
//         <Layout>
//           <Component {...props} />
//         </Layout>
//       )}
//     />
//   );
// };

const App = () => {
  //   const { currentNetwork } = useContext(GlobalState);
  //   let [currentClient, setCurrentClient] = useState(initialClient);
  //   useEffect(() => {
  //     if (currentNetwork) {
  //       setupClient(currentNetwork).then((client) => setCurrentClient(client));
  //     }
  //   }, [currentNetwork]);

  return (
    <>
      <div>hi</div>
      <BrowserRouter>
        <Switch>
          <DefaultRoute
            exact
            path="/"
            component={Home}
            layout={HomePageLayout}
          />
          {/* <Route path="/test-registrar" component={TestRegistrar} />
        <Route path="/favourites" component={Favourites} />
        <Route path="/faq" component={Faq} />
        <Route path="/my-bids" component={SearchResults} />
        <Route path="/how-it-works" component={SearchResults} />
        <Route path="/search/:searchTerm" component={SearchResults} />
        <Route path="/name/:name" component={SingleName} />
        <Route path="/address/:address/:domainType" component={Address} />
        <Route path="/address/:address" component={Address} />
        <Route path="/renew" component={Renew} /> */}
          <DefaultRoute path="*" component={Error404} />
        </Switch>
      </BrowserRouter>
    </>
  );
};

export default App;
