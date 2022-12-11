import React from 'react';
import {
    BrowserRouter,
    Routes,
    Route,
} from "react-router-dom";
import {ContractsProvider} from "../contexts/ContractsContext";
import MyAppBar from "components/AppBar";
import Mint from "views/Mint";
import Cards from "views/Cards";

import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import Toolbar from '@mui/material/Toolbar';
import List from '@mui/material/List';
import Typography from '@mui/material/Typography';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Chip from '@mui/material/Chip';
import Tooltip from '@mui/material/Tooltip';

import Inventory2OutlinedIcon from '@mui/icons-material/Inventory2Outlined';
import StorefrontIcon from '@mui/icons-material/Storefront';
import ShoppingBagOutlinedIcon from '@mui/icons-material/ShoppingBagOutlined';
import PaidIcon from '@mui/icons-material/Paid';
import GppBadIcon from '@mui/icons-material/GppBad';
import FilterNoneIcon from '@mui/icons-material/FilterNone';

const Console = () => {

    return (
        <ContractsProvider>
            <MyAppBar/>
            <Drawer
                variant="permanent"
                sx={{
                    width: 240,
                    flexShrink: 0,
                    [`& .MuiDrawer-paper`]: {width: 240, boxSizing: 'border-box'},
                }}
            >
                <Toolbar/>
                <Box sx={{overflow: 'auto'}}>
                    <List>
                        <ListItem disablePadding>
                            <ListItemButton>
                                <ListItemIcon>
                                    <Inventory2OutlinedIcon/>
                                </ListItemIcon>
                                <ListItemText primary={'Inventory'}/>
                            </ListItemButton>
                        </ListItem>
                        <ListItem disablePadding>
                            <ListItemButton>
                                <ListItemIcon>
                                    <ShoppingBagOutlinedIcon/>
                                </ListItemIcon>
                                <ListItemText primary={'Mint'}/>
                            </ListItemButton>
                        </ListItem>
                        <ListItem disablePadding>
                            <ListItemButton>
                                <ListItemIcon>
                                    <StorefrontIcon/>
                                </ListItemIcon>
                                <ListItemText primary={'Blackmarket'}/>
                            </ListItemButton>
                        </ListItem>
                    </List>
                </Box>
            </Drawer>
            <Box component="main" sx={{flexGrow: 1, p: 3}}>
                <BrowserRouter>
                    <Routes>
                        <Route path="/mint" element={<Mint/>}/>
                        <Route path="/" element={<Cards/>}/>
                    </Routes>
                </BrowserRouter>

            </Box>
        </ContractsProvider>
    );
};

export default Console;
