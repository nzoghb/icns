import React, { Fragment } from 'react'

// import Header from '../Header/Header'
import SideNav from '../components/SideNav'
import Main from './Main'
import Container from './Container'

const DefaultLayout = ({ children }) => (
  <Fragment>
    {/* <Header /> */}
    <Container>
      <SideNav />
      <Main>{children}</Main>
    </Container>
  </Fragment>
)

export default DefaultLayout
