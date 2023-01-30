import React, { useState, useEffect } from 'react';
import { Form, Steps, Divider, Row, Col, Checkbox, Input, InputNumber, Button, Space, Slider, TimePicker, Select, Typography, message } from 'antd';
import { ClearOutlined, LayoutOutlined, GroupOutlined, LeftOutlined, RightOutlined, DownloadOutlined, CloseCircleOutlined, PlusOutlined } from '@ant-design/icons';
import './App.css';

import config_basic from './config_basic.js'
import config_office from './config_office'

import moment from 'moment';
const { Option } = Select;
const { Step } = Steps;
const { Title } = Typography;


const App = () => {

  const [form] = Form.useForm();
  // const initialState = {"people": [], "events": [], "places": [], "options": []}
  const initialState = {
    "people": [{
      "department": null, "building": null, "num_people": null
    }],
    "events": [{
      "activity": null, 
      "schedule": [{"schedule": [moment().hour(0).minute(0), moment().hour(23).minute(45)]}],
      "repeat": [2,10],
      "duration": [15,45], 
      "mask_efficiency": null,
      "collective": false, "shared": false, "allow": true
    }],
    "places": [{
      "name": null, "activity": null, "building": null, 
      "department": null, "area": null, "height": null, "capacity": null,
      "ventilation": null, "recirculated_flow_rate": null, "allow": true
    }],
    "options": {
      "movement_buildings": true,
      "movement_department": true,
      "number_runs": 1,
      "save_log": true,
      "save_config": false,
      "save_csv": true,
      "save_json": false,
      "return_output": true,
      "directory": null,
      "ratio_infected": 0.05*100,
      "model": "Colorado",
      "model_parameters": {
          "Colorado": {
              "pressure": 0.95,
              "temperature": 20,
              "CO2_background": 415,
              "decay_rate": 0.62,
              "deposition_rate": 0.3,
              "hepa_flow_rate": 0.0,
              "filter_efficiency": 0.20*100,
              "ducts_removal": 0.10*100,
              "other_removal": 0.00*100,
              "fraction_immune": 0*100,
              "breathing_rate": 0.52,
              "CO2_emission_person": 0.005,
              "quanta_exhalation": 25,
              "quanta_enhancement": 1,
              "people_with_masks": 1.00*100
          }
      }
  }
  }
  // const initialState = {}
  const [state, setState] = useState(initialState);
  const [current, setCurrent] = useState(0);
  const [eventsDisabled, setEventsDisabled] = useState({});
  const [placesDisabled, setPlacesDisabled] = useState({});
  
  useEffect(() => {
    // form.validateFields(['events', 'activity']);
    console.log("hey")
    
  }, [current]);

  const onlyUnique = (value, index, self) => {
    return self.indexOf(value) === index;
  }

  const onChangePlace = (e, field_name) => {
    console.log("updating", field_name, e.activity, field_name, placesDisabled)
    // setPlacesDisabled({
    //   ...placesDisabled,
    //   [field_name]: true
    // })
    let places = form.getFieldValue(["places"])
    let events = form.getFieldValue(["events"])
    console.log(events)
    if(places[field_name] === undefined){
      setPlacesDisabled({
        ...placesDisabled,
        [field_name]: true
      })
      return
    }
    let activity = places[field_name].activity
    if(activity === null || activity === undefined){
      setPlacesDisabled({
        ...placesDisabled,
        [field_name]: true
      })
      return
    }
    if(events.length > 0){
      let event = events.find(e => e.activity === activity)
      if("shared" in event){
        setPlacesDisabled({
          ...placesDisabled,
          [field_name]: events.find(e => e.activity === activity).shared
        })
        return
      }
    }
    setPlacesDisabled({
      ...placesDisabled,
      [field_name]: true
    })

  }

  const onChangeEvent = (e, field_name) => {
    let events = form.getFieldValue(["events"])
    if(events[field_name] !== undefined){
      setEventsDisabled({
        ...eventsDisabled,
        [field_name]: events[field_name].shared
      })
      // eventsDisabled[field_name] = events[field_name].shared
      return
    }
    setEventsDisabled({
      ...eventsDisabled,
      [field_name]: true
    })
    // eventsDisabled[field_name] = true
  }

  const modelName = "Colorado"


  const renderPeople = () => {
    return (

      <Form.List
        name="people"
        initialValue={[{
          "department": null, "building": null, "num_people": null
        }]}
      >
        {(fields, { add, remove }) => (
          <div>
            {fields.map((field, index) => (
              <Space key={field.key} style={{ display: 'flex', marginBottom: 0 }} align="start" size="large">
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Department" : ""}
                  labelCol={{ span: 20, offset: 0 }}
                  // wrapperCol={{span: 24}}
                  name={[field.name, 'department']}
                  fieldKey={[field.fieldKey, 'department']}
                  rules={[{ required: true, message: 'Missing department (name)' }]}
                  tooltip="Department name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Input placeholder="Department" />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Building" : ""}
                  name={[field.name, 'building']}
                  fieldKey={[field.fieldKey, 'building']}
                  rules={[{ required: true, message: 'Missing building (name)' }]}
                  tooltip="Building name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Input placeholder="Building" />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "People" : ""}
                  name={[field.name, 'num_people']}
                  fieldKey={[field.fieldKey, 'num_people']}
                  rules={[{ required: true, message: 'Missing people (numeric)' }]}
                  tooltip="Number of people"
                  style={{ marginBottom: 4, display: "block", width: '90px' }}
                  initialValue={null}
                >
                  <InputNumber 
                    min={1} 
                    placeholder="People" 
                  />
                </Form.Item>

                <Button
                  type="text"
                  disabled={index === 0}
                  onClick={() => remove(field.name)}
                  icon={<CloseCircleOutlined />}
                  style={{ marginTop: index === 0 ? 32 : 0 }}
                  shape="circle"
                />

              </Space>
            ))}
            <Form.Item>
              <Button
                type="dashed"
                onClick={() => add()}
                icon={<PlusOutlined />}
                style={{ width: "150px" }}
              >
                Add department
              </Button>
            </Form.Item>
          </div>
        )}
      </Form.List>
    )
  };

  const renderEvents = () => {
    return (
      <Form.List
        name="events"
        initialValue={[{
          "activity": null, 
          "schedule": [{"schedule": [moment().hour(0).minute(0), moment().hour(23).minute(45)]}],
          "repeat": [2,10],
          "duration": [15,45], 
          "mask_efficiency": null,
          "collective": false, "shared": false, "allow": true
        }]}
      >
        {(fields, { add, remove }) => (
          <>
            {fields.map((field, index) => (
              <Space key={field.key} style={{ display: 'flex', marginBottom: 0 }} align="start" size="large">
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Activity" : ""}
                  name={[field.name, 'activity']}
                  fieldKey={[field.fieldKey, 'activity']}
                  rules={[{ required: true, message: 'Missing activity' }]}
                  tooltip="Event name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  {/* <Input placeholder="Activity" disabled={state["allowevent"+index]}/> */}
                  <Input placeholder="Activity" />
                </Form.Item>
                <Form.List
                  name={[field.name, 'schedule']}
                  initialValue={[{
                  }]}
                >
                  {(schedules, { add, remove }) => (
                    <div>
                      {schedules.map((schedule, index2) => (
                        <Space key={schedule.key} style={{ display: 'flex', marginBottom: 0 }} align="start">
                          <Form.Item
                            {...schedule}
                            colon={false}
                            label={index === 0 & index2 === 0 ? "Schedule" : ""}
                            name={[schedule.name, 'schedule']}
                            fieldKey={[schedule.fieldKey, 'schedule']}
                            rules={[{ required: true, message: 'Missing schedule' }]}
                            tooltip="Times when an event is permitted to happen"
                            style={{ marginBottom: 4, display: 'block', width: '150px' }}
                            // normalize={value => value.map(e => moment.unix(60*e.hours()+e.minutes()))}
                            // normalize={value => value.map(e => 60)}
                            // getValueFromEvent={(value) => value.map(e => 60*e.hours()+e.minutes())}
                          >
                            <TimePicker.RangePicker 
                              format="HH:mm" 
                              minuteStep={15} 
                              disabledSeconds={0}
                              placeholder={["start", "end"]}
                            />
                          </Form.Item>

                          <Button
                            type="text"
                            onClick={() => remove(schedule.name)}
                            icon={<CloseCircleOutlined />}
                            disabled={index2 === 0}
                            style={{ marginTop: (index === 0 && index2 === 0) ? 32 : 0 }}
                            shape="circle"
                          />

                        </Space>
                      ))}
                      <Form.Item>
                        <Button
                          type="dashed"
                          onClick={() => add()}
                          size="small"
                          icon={<PlusOutlined />}
                          style={{ width: "150px" }}
                        >
                          Add interval
                        </Button>
                      </Form.Item>
                    </div>
                  )}
                </Form.List>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Repetitions" : ""}
                  name={[field.name, 'repeat']}
                  fieldKey={[field.fieldKey, 'repeat']}
                  rules={[{ required: true, message: 'Missing repeat' }]}
                  tooltip="Number of repetitions. Only shared events have lower and upper bounds"
                  style={{ marginBottom: 4, display: 'block', width: '110px' }}
                  initialValue={[2, 10]}
                >
                  <Slider
                    placeholder="Repetition"
                    range
                    step={1}
                    min={1}
                    max={60}
                    tipFormatter={value => `${value} times`}
                    tooltipPlacement="bottom"
                    disabled={!eventsDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Duration" : ""}
                  name={[field.name, 'duration']}
                  fieldKey={[field.fieldKey, 'duration']}
                  rules={[{ required: true, message: 'Missing duration' }]}
                  tooltip="Event duration lower and upper bounds, in minutes"
                  style={{ marginBottom: 4, display: 'block', width: '110px' }}
                  initialValue={[15, 45]}
                >
                  <Slider
                    placeholder="Duration"
                    range
                    step={1}
                    min={1}
                    max={60}
                    tipFormatter={value => `${value}mins`}
                    tooltipPlacement="bottom"
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Mask efficiency" : ""}
                  name={[field.name, 'mask_efficiency']}
                  fieldKey={[field.fieldKey, 'mask_efficiency']}
                  rules={[{ required: eventsDisabled[field.name], message: 'Missing mask efficiency' }]}
                  tooltip="Mask efficiency during an event"
                  style={{ marginBottom: 4, display: 'block', width: '130px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="eff"
                    disabled={!eventsDisabled[field.name]}
                    min={0}
                    max={100}
                    addonAfter="%"
                    style={{ width: '110px'}}
                    // parser={value => parseInt(value) / 100.0}
                    // formatter={value => `${value}%`}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Collective" : ""}
                  name={[field.name, 'collective']}
                  fieldKey={[field.fieldKey, 'collective']}
                  tooltip="Event is invoked by one person but involves many. Only activated on shared events."
                  style={{ marginBottom: 4, display: 'block', width: '80px' }}
                  valuePropName="checked"
                  initialValue={false}
                >
                  <Checkbox disabled={!eventsDisabled[field.name]}/>
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Shared" : ""}
                  name={[field.name, 'shared']}
                  fieldKey={[field.fieldKey, 'shared']}
                  tooltip="Whether the space is shared by many people. Use it to create independent places for each person (their house, for example)"
                  style={{ marginBottom: 4, display: 'block', width: '70px' }}
                  valuePropName="checked"
                  initialValue={true}
                  >
                  <Checkbox onChange={e => onChangeEvent(e, field.name)}/>

                </Form.Item>

                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Allow" : ""}
                  name={[field.name, 'allow']}
                  fieldKey={[field.fieldKey, 'allow']}
                  rules={[{ required: false, message: 'Missing allow' }]}
                  tooltip="This is a required field"
                  style={{ marginBottom: 4, display: 'none', visibility: 'hidden'}}
                  valuePropName="checked"
                  initialValue={true}
                  hidden={true}
                >
                  <Checkbox/>
                </Form.Item>
                <Button
                  type="text"
                  disabled={index === 0}
                  onClick={async () => {
                    await remove(field.name)
                    await form.getFieldValue(["events"]).map((e, index) => onChangeEvent(e, index))
                  }}
                  icon={<CloseCircleOutlined />}
                  style={{ marginTop: index === 0 ? 32 : 0 }}
                  shape="circle"
                />
              </Space>
            ))}
            <Form.Item>
              <Button
                type="dashed"
                onClick={async () => {
                  await add()
                  await form.getFieldValue(["events"]).map((e, index) => onChangeEvent(e, index))
                }}
                block
                icon={<PlusOutlined />}
                style={{ width: "150px" }}
              >
                Add event
              </Button>
            </Form.Item>
          </>
        )}
      </Form.List>
    )
  };

  const renderPlaces = () => {
    return (
      <Form.List
        name="places"
      initialValue={[{
            "name": null, "activity": null, "building": null, 
            "department": null, "area": null, "height": null, "capacity": null,
            "ventilation": null, "recirculated_flow_rate": null, "allow": true
       }]}
      >
        {(fields, { add, remove }) => (
          <>
            {fields.map((field, index) => (
              <Space key={field.key} style={{ display: 'flex', marginBottom: 0 }} align="start">
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Name" : ""}
                  name={[field.name, 'name']}
                  fieldKey={[field.fieldKey, 'name']}
                  rules={[{ required: true, message: 'Missing name' }]}
                  tooltip="Place name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Input placeholder="Name" />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Activity" : ""}
                  name={[field.name, 'activity']}
                  fieldKey={[field.fieldKey, 'activity']}
                  rules={[{ required: true, message: 'Missing activity' }]}
                  tooltip="Activity or event occurring at that place"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Select placeholder="Activity" onChange={e => onChangePlace(e, field.name)} onSelect={e => onChangePlace(e, field.name)}>
                    {(form.getFieldValue("events") || []).map(item => (
                      <Option key={[field.name, "activity", item.activity]} value={item.activity}>
                        {item.activity}
                      </Option>
                    ))}
                  </Select>

                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Building" : ""}
                  name={[field.name, 'building']}
                  fieldKey={[field.fieldKey, 'building']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing building' }]}
                  tooltip="Building name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Select placeholder="Building" disabled={!placesDisabled[field.name]}>
                    {(form.getFieldValue("people") || []).map(item => item.building).filter(onlyUnique).map(item => (
                      <Option key={[field.name, "building", item]} value={item}>
                        {item}
                      </Option>
                    ))}
                  </Select>
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Department" : ""}
                  name={[field.name, 'department']}
                  fieldKey={[field.fieldKey, 'department']}
                  rules={[{ required: false, message: 'Missing department' }]}
                  tooltip="Department name"
                  style={{ marginBottom: 4, display: 'block', width: '150px' }}
                  initialValue={null}
                >
                  <Select 
                    mode="multiple"
                    allowClear
                    placeholder="Department"
                    disabled={!placesDisabled[field.name]}
                  >
                    {(form.getFieldValue("people") || []).map(item => (
                      <Option key={[field.name, "department", item.department]} value={item.department}>
                        {item.department}
                      </Option>
                    ))}

                  </Select>
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Area" : ""}
                  name={[field.name, 'area']}
                  fieldKey={[field.fieldKey, 'area']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing area' }]}
                  tooltip="Room floor area in square meters."
                  style={{ marginBottom: 4, display: 'block', width: '80px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="Area"
                    controls={false}
                    min={1}
                    addonAfter="m²"
                    disabled={!placesDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Height" : ""}
                  name={[field.name, 'height']}
                  fieldKey={[field.fieldKey, 'height']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing height' }]}
                  tooltip="Room height in meters."
                  style={{ marginBottom: 4, display: 'block', width: '80px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="Height"
                    controls={false}
                    min={1}
                    addonAfter="m"
                    disabled={!placesDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Capacity" : ""}
                  name={[field.name, 'capacity']}
                  fieldKey={[field.fieldKey, 'capacity']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing capacity' }]}
                  tooltip="Room people capacity."
                  style={{ marginBottom: 4, display: 'block', width: '90px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="Capacity"
                    controls={false}
                    min={1}
                    addonAfter="-"
                    disabled={!placesDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Ventilation" : ""}
                  name={[field.name, 'ventilation']}
                  fieldKey={[field.fieldKey, 'ventilation']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing ventilation' }]}
                  tooltip="Outdoor or natural air exchange rate"
                  style={{ marginBottom: 4, display: 'block', width: '100px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="Ventilation"
                    controls={false}
                    min={0}
                    addonAfter="1/h"
                    disabled={!placesDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Recirculated flow" : ""}
                  name={[field.name, 'recirculated_flow_rate']}
                  fieldKey={[field.fieldKey, 'recirculated_flow_rate']}
                  rules={[{ required: placesDisabled[field.name], message: 'Missing recirculated_flow_rate' }]}
                  tooltip="Recirculating or mechanical air exchange rate"
                  style={{ marginBottom: 4, display: 'block', width: '140px' }}
                  initialValue={null}
                >
                  <InputNumber
                    // placeholder="Recirculated flow rate"
                    controls={false}
                    min={0}
                    addonAfter="m³/h"
                    disabled={!placesDisabled[field.name]}
                  />
                </Form.Item>
                <Form.Item
                  {...field}
                  colon={false}
                  label={index === 0 ? "Allow" : ""}
                  name={[field.name, 'allow']}
                  fieldKey={[field.fieldKey, 'allow']}
                  rules={[{ required: false, message: 'Missing allow' }]}
                  tooltip="This is a required field"
                  valuePropName="checked"
                  style={{ marginBottom: 4, display: 'hidden', visibility: 'hidden' }}
                  initialValue={true}
                  hidden={true}
                >
                  <Checkbox />
                </Form.Item>

                <Button
                  type="text"
                  disabled= {index === 0}
                  onClick={async () => {
                    await remove(field.name)
                    await form.getFieldValue(["places"]).map((e, index) => onChangePlace(e, index))
                  }}
                  icon={<CloseCircleOutlined />}
                  style={{ marginTop: index === 0 ? 32 : 0 }}
                  shape="circle"
                />
              </Space>
            ))}
            <Form.Item>
              <Button
                type="dashed"
                onClick={async () => {
                  await add()
                  await form.getFieldValue(["places"]).map((e, index) => onChangePlace(e, index))
                }}
                block
                icon={<PlusOutlined />}
                style={{ width: '150px' }}
              >
                Add place
              </Button>
            </Form.Item>
          </>
        )}
      </Form.List>
    )
  };

  const renderOptions = () => {
    return (
      <div>
        <Row>

          <Col span={12}>
            <Divider orientation="center">Simulation settings</Divider>
            <Form.Item
              colon={false}
              label={"Move between buildings"}
              name={['options', 'movement_buildings']}
              fieldKey={['options', 'movement_buildings']}
              rules={[{ required: false, message: 'Missing buildings movement' }]}
              tooltip="Allow people to enter other buildings"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={true}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Move between departments"}
              name={['options', 'movement_department']}
              fieldKey={['options', 'movement_department']}
              rules={[{ required: false, message: 'Missing department movement' }]}
              tooltip="Allow people to enter other departments"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={true}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Ratio infected"}
              name={['options', 'ratio_infected']}
              fieldKey={['options', 'ratio_infected']}
              rules={[{ required: true, message: 'Missing ratio infected' }]}
              tooltip="Ratio of infected to total number of people"
              style={{ marginBottom: 4 }}
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={5}
            >
              <InputNumber
                placeholder={5}
                min={0}
                max={100}
                addonAfter="%"
                // parser={value => parseInt(value) / 100.0}
                style={{ width: "150px" }}
                controls={false}
              // formatter={value => `${value}%`}
              // parser={value => value.replace('%', '')}
              />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Number of runs"}
              name={['options', 'number_runs']}
              fieldKey={['options', 'number_runs']}
              rules={[{ required: true, message: 'Missing number of runs' }]}
              tooltip="Number of simulations runs to execute"
              style={{ marginBottom: 4 }}
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={1}
            >
              <InputNumber 
                placeholder={1}
                min={1}
                style={{ width: '150px' }} 
              />
            </Form.Item>

            <Divider orientation="center">Export settings</Divider>
            <Form.Item
              colon={false}
              label={"Save log"}
              name={['options', 'save_log']}
              fieldKey={['options', 'save_log']}
              rules={[{ required: false, message: 'Missing log save' }]}
              tooltip="Save events logs"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={true}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Save configuration"}
              name={['options', 'save_config']}
              fieldKey={['options', 'save_config']}
              rules={[{ required: false, message: 'Missing config save' }]}
              tooltip="Save configuration file"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={true}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Save csv format"}
              name={['options', 'save_csv']}
              fieldKey={['options', 'save_csv']}
              rules={[{ required: false, message: 'Missing csv export' }]}
              tooltip="Export the results to csv format"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={true}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Save json format"}
              name={['options', 'save_json']}
              fieldKey={['options', 'save_json']}
              rules={[{ required: false, message: 'Missing json export' }]}
              tooltip="Export the results to json format"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={false}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Return object"}
              name={['options', 'return_output']}
              fieldKey={['options', 'return_output']}
              rules={[{ required: false, message: 'Missing return results' }]}
              tooltip="Return a dictionary with the results"
              style={{ marginBottom: 4 }}
              valuePropName="checked"
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={false}
            >
              <Checkbox />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Directory"}
              name={['options', 'directory']}
              fieldKey={['options', 'directory']}
              rules={[{ required: false, message: 'Missing directory' }]}
              tooltip="Directory name to save results"
              style={{ marginBottom: 4 }}
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={"results"}
            >
              <Input placeholder="results" style={{ width: "150px" }} />
            </Form.Item>
            <Form.Item
              colon={false}
              label={"Model name"}
              name={['options', 'model']}
              fieldKey={['options', 'model']}
              rules={[{ required: false, message: 'Model' }]}
              tooltip="Aerosol model to be used in the simulation. For the moment, only supports one model, so option disabled"
              style={{ marginBottom: 4 }}
              labelCol={{ span: 9 }}
              wrapperCol={{ span: 16 }}
              initialValue={modelName}
            >
              <Input placeholder={modelName} disabled style={{ width: "150px" }} />
            </Form.Item>

          </Col>

          <Col span={12}>

            <Divider orientation="center">Aerosol model settings</Divider>
            <div>
              <Form.Item
                colon={false}
                label={"Pressure"}
                name={['options', 'model_parameters', modelName, 'pressure']}
                fieldKey={['options', 'model_parameters', modelName, 'pressure']}
                rules={[{ required: true, message: 'Missing pressure' }]}
                tooltip="Ambient pressure in atm"
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0.95}
              >
                <InputNumber placeholder={0.95} min={0} addonAfter="atm" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Temperature"}
                name={['options', 'model_parameters', modelName, 'temperature']}
                fieldKey={['options', 'model_parameters', modelName, 'temperature']}
                rules={[{ required: true, message: 'Missing temperature' }]}
                tooltip="Ambient temperature in Celsius degrees"
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={20}
              >
                <InputNumber placeholder={20} min={0} addonAfter="ºC" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Background CO2"}
                name={['options', 'model_parameters', modelName, 'CO2_background']}
                fieldKey={['options', 'model_parameters', modelName, 'CO2_background']}
                rules={[{ required: true, message: 'Missing background CO2' }]}
                tooltip="Background CO2 concentration in ppm"
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={415}
              >
                <InputNumber placeholder={415} min={0} addonAfter="ppm" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Decay rate"}
                name={['options', 'model_parameters', modelName, 'decay_rate']}
                fieldKey={['options', 'model_parameters', modelName, 'decay_rate']}
                rules={[{ required: true, message: 'Missing decay rate' }]}
                tooltip={<span>
                  Decay rate of the virus infectivity in aerosols (indoors and outdoors). Literature values in h-1: 0.63
                  Online
                  <a target="_blank" rel="noreferrer" href="https://www.dhs.gov/science-and-technology/sars-airborne-calculator"> estimator </a>
                  for a given T, RH, UV.
                  </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0.62}
              >
                <InputNumber placeholder={0.62} min={0} addonAfter="1/h" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Deposition rate"}
                name={['options', 'model_parameters', modelName, 'deposition_rate']}
                fieldKey={['options', 'model_parameters', modelName, 'deposition_rate']}
                rules={[{ required: true, message: 'Missing deposition_rate' }]}
                tooltip="Deposition to surfaces. Buonnano et al. (2020), Miller et al. (2020). Could vary 0.24-1.5 h-1, depending on particle size range."
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0.3}
              >
                <InputNumber placeholder={0.3} min={0} addonAfter="1/h" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"HEPA flow rate"}
                name={['options', 'model_parameters', modelName, 'hepa_flow_rate']}
                fieldKey={['options', 'model_parameters', modelName, 'hepa_flow_rate']}
                rules={[{ required: true, message: 'Missing hepa flow rate' }]}
                tooltip={<span>
                  HEPA (high efficiency particulate air) filters flow rate. Use this HEPA filter 
                  <a target="_blank" rel="noreferrer" href="https://tinyurl.com/portableaircleanertool"> calculator </a>
                  </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0}
              >
                <InputNumber placeholder={0} min={0} addonAfter="m³/h" style={{ width: "150px" }} />
              </Form.Item>
              {/* <Form.Item
                colon={false}
                name={['options', 'model_parameters', 'recirculated_flow_rate']}
                fieldKey={['options', 'model_parameters', 'recirculated_flow_rate']}
                rules={[{ required: true, message: 'Missing recirculated flow rate' }]}
                tooltip="This is a required field"
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
              >
                <InputNumber placeholder="Recirculated flow rate" min={0} addonAfter="m³/h" style={{width: "150px"}}/>
              </Form.Item> */}
              <Form.Item
                colon={false}
                label={"Filter efficiency"}
                name={['options', 'model_parameters', modelName, 'filter_efficiency']}
                fieldKey={['options', 'model_parameters', modelName, 'filter_efficiency']}
                rules={[{ required: true, message: 'Missing filter efficiency' }]}
                tooltip={<span>
                  Air conditioning filter efficiency. 
                  <a target="_blank" rel="noreferrer" href="https://www.nafahq.org/understanding-merv-nafa-users-guide-to-ansi-ashrae-52-2/"> Table of filter efficiency. </a>
                  Use the table to convert from particle size (1-10 um, based on the literature) to filter efficiency.
                  </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={20}
              >
                <InputNumber
                  placeholder={20}
                  min={0}
                  max={100}
                  addonAfter="%"
                  // parser={value => parseInt(value) / 100.0}
                  style={{ width: "150px" }}
                />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Ducts removal"}
                name={['options', 'model_parameters', modelName, 'ducts_removal']}
                fieldKey={['options', 'model_parameters', modelName, 'ducts_removal']}
                rules={[{ required: true, message: 'Missing ducts removal' }]}
                tooltip="Air ducts removal loss. Assuming some losses in bends, air handler surfaces etc."
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={10}
              >
                <InputNumber
                  placeholder={10}
                  min={0}
                  max={100}
                  addonAfter="%"
                  // parser={value => parseInt(value) / 100.0}
                  style={{ width: "150px" }}
                />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Other removal"}
                name={['options', 'model_parameters', modelName, 'other_removal']}
                fieldKey={['options', 'model_parameters', modelName, 'other_removal']}
                rules={[{ required: true, message: 'Missing other removal' }]}
                tooltip="Other removal measures, such as germicidal UV."
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0}
              >
                <InputNumber
                  placeholder={0}
                  min={0}
                  max={100}
                  addonAfter="%"
                  // parser={value => parseInt(value) / 100.0}
                  style={{ width: "150px" }}
                />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Fraction immune"}
                name={['options', 'model_parameters', modelName, 'fraction_immune']}
                fieldKey={['options', 'model_parameters', modelName, 'fraction_immune']}
                rules={[{ required: true, message: 'Missing fraction immune' }]}
                tooltip="Fraction of population inmune to the virus. From vaccination or disease (seroprevalence reports), will depend on each location and time."
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0}
              >
                <InputNumber
                 placeholder={0}
                  min={0}
                  max={100}
                  addonAfter="%"
                  // parser={value => parseInt(value) / 100.0}
                  style={{ width: "150px" }}
                />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Breathing rate"}
                name={['options', 'model_parameters', modelName, 'breathing_rate']}
                fieldKey={['options', 'model_parameters', modelName, 'breathing_rate']}
                rules={[{ required: true, message: 'Missing breathing rate' }]}
                tooltip={<span>
                  Breathing rate (susceptibles): Varies a lot with activity level.
                  Recommended values from 
                  <a target="_blank" rel="noreferrer" href="https://www.epa.gov/expobox/exposure-factors-handbook-chapter-6"> US EPA Exposure Factors Handbook </a>
                  (Chapter 6), depend on age and activity level.
                  </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0.52}
              >
                <InputNumber  placeholder={0.52} min={0} addonAfter="m³/h" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"CO2 emission per person"}
                name={['options', 'model_parameters', modelName, 'CO2_emission_person']}
                fieldKey={['options', 'model_parameters', modelName, 'CO2_emission_person']}
                rules={[{ required: true, message: 'Missing CO2 emission per person' }]}
                tooltip={<span>
                CO2 emission rate (1 person) @ 273K and 1 atm.
                <a target="_blank" rel="noreferrer" href="https://onlinelibrary.wiley.com/doi/full/10.1111/ina.12383"> Persily and de Jonge (2017)</a>
                </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={0.005}
              >
                <InputNumber placeholder={0.005} min={0} addonAfter="ppm" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Quanta exhalation"}
                name={['options', 'model_parameters', modelName, 'quanta_exhalation']}
                fieldKey={['options', 'model_parameters', modelName, 'quanta_exhalation']}
                rules={[{ required: true, message: 'Missing quanta exhalation' }]}
                tooltip={<span>
                  Quanta emission rates for SARS-CoV-2. Depends strongly on activity. 
                  <a target="_blank" rel="noreferrer" href="https://doi.org/10.1016/j.envint.2020.106112"> Buonnano et al. 2020 </a>  provides a range of estimates:
                  For oral breathing, speaking and aloud speaking respectively: resting 2.0, 9.4 and 60.5; standing 2.3, 11.4, 65.1; light exercise 5.6, 26.3, 170; and heavy exercise 13.5, 63.1, 408 quanta/hour.
                  For children as a first approximation reduce these numbers proportionally to body mass.
                </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={25}
              >
                <InputNumber placeholder={25} min={0} addonAfter="quanta/h" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"Quanta enhancement"}
                name={['options', 'model_parameters', modelName, 'quanta_enhancement']}
                fieldKey={['options', 'model_parameters', modelName, 'quanta_enhancement']}
                rules={[{ required: true, message: 'Missing quanta enhancement' }]}
                tooltip={<span>
                  Quanta enhancement due to variants. 1 for the original variant, can be higher for variants of concern. 
                  We recommend using values from the
                  <a target="_blank" rel="noreferrer" href="https://www.cdc.gov/coronavirus/2019-ncov/variants/variant-classifications.html?CDC_AA_refVal=https%3A%2F%2Fwww.cdc.gov%2Fcoronavirus%2F2019-ncov%2Fvariants%2Fvariant-info.html"> CDC variant surveillance page. </a>
                   As of 2-May-2021, the values are 1.5 for the UK and South African variants, and 1.2 for the California variants. 
                </span>}
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={1}
              >
                <InputNumber placeholder={1} min={0} max={1} addonAfter="quanta" style={{ width: "150px" }} />
              </Form.Item>
              <Form.Item
                colon={false}
                label={"People with masks"}
                name={['options', 'model_parameters', modelName, 'people_with_masks']}
                fieldKey={['options', 'model_parameters', modelName, 'people_with_masks']}
                rules={[{ required: true, message: 'Missing people with masks' }]}
                tooltip="Fraction of people with masks"
                style={{ marginBottom: 4 }}
                labelCol={{ span: 9 }}
                wrapperCol={{ span: 16 }}
                initialValue={100}
              >
                <InputNumber
                  placeholder={100}
                  min={0}
                  max={100}
                  addonAfter="%"
                  // parser={value => parseInt(value) * 100.0}
                  style={{ width: "150px" }}
                />
              </Form.Item>
            </div>

          </Col>
        </Row>
      </div>
    )
  };

  const renderStepsButtons = () => {
    return (
      <Form.Item>
        {current > 0 && (
          <Button type="ghost" shape="default" onClick={() => onPrev()}>
          <LeftOutlined />
          Previous
          </Button>
        )}
        {current < 3 && (
          <Button type="primary" shape="default" onClick={() => onNext()}>
          Next
          <RightOutlined />
          </Button>
        )}
        {current === 3 && (
          <Button 
            type="primary" 
            shape="default" 
            icon={<DownloadOutlined />} 
            onClick={onDownload}
            htmlType="submit"
          >
            config.json
          </Button>
        )}
      </Form.Item>
    )
  }

 

  const onNext = () => {
    form.validateFields()
      .then(response => {
        setCurrent(current + 1);
      })
      .catch(error => {})
  };

  const onPrev = () => {
    form.validateFields()
      .then(response => {
        setCurrent(current - 1);
      })
      .catch(error => {})
  };

  const onFinish = () => {
    message.success('Processing complete!')
  };

  const onFinishFailed = () => {
    message.error('Complete required fields!')
  };

  const onStepsChange = (current) => {
    form.validateFields()
      .then(response => {
        setCurrent(current);
      })
      .catch(error => {})
  };

  const onFieldsChange = (changedFields, allFields) => {
    // console.log(changedFields, allFields, form.getFieldsValue(true))
    setState(allFields)
  };

  const onDownload = () => {
    // let data = form.getFieldsValue(true)
    // let dataJSON = JSON.stringify(data, null, 2)
    let dataJSON = configBuilder()
    let dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(dataJSON);
    let a = document.createElement('a');
    a.setAttribute("href", dataStr);
    a.setAttribute("download", "config.json");
    document.body.appendChild(a);
    a.click();
    a.remove();
  };

  const onLoad = (config) => {
    setCurrent(0)
    let tmp = configParser(config)
    form.setFieldsValue(tmp)
    setState(tmp)
    if("events" in tmp){
      console.log("events")
      tmp.events.map((e, index) => onChangeEvent(e, index))
    }
    setTimeout(() => {
      console.log("places")
      if("places" in tmp){
        tmp.places.map((e, index) => onChangePlace(e, index))
      }
    }, 2000);
  }

  const onClear = () => {
    // form.resetFields()
    // setState({})
    setCurrent(0)
    form.setFieldsValue(initialState)
    setState(initialState)
  }

  const time2mins = (time) => {
    time = moment(time)
    return time.hours() * 60 + time.minutes()
  }

  const mins2time = (minutes) => {
    let hour = (minutes / 60) >> 0
    let minute = minutes % 60
    return moment({ hour, minute })
  }

  // from builder to archABM
  const configBuilder = () => {
    let d = form.getFieldsValue(true)
    // return JSON.stringify(d, null, 2)
    let data = JSON.parse(JSON.stringify(d))
    
    if ("events" in data){
      data.events.forEach(event => {
        if(event !== null && "schedule" in event && event.schedule !== null){
          event.schedule = event.schedule.map(interval => {
              if(interval !== null && "schedule" in interval){
                return interval.schedule.map(time2mins)
              }
              return interval
          })         
        }
        if(event !== null && "repeat" in event){
          event.repeat_min = event.repeat[0]
          event.repeat_max = event.repeat[1]
          delete event.repeat
        }
        if(event !== null && "duration" in event){
          event.duration_min = event.duration[0]
          event.duration_max = event.duration[1]
          delete event.duration
        }
        if(event !== null && "mask_efficiency" in event){
          event.mask_efficiency /= 100
        }
      })
    }
    if("options" in data){
      if(data.options !== null && "ratio_infected" in data.options){
        data.options.ratio_infected /= 100
      }
      if(data.options !== null && "model_parameters" in data.options){
        if(data.options.model_parameters !== null  && modelName in data.options.model_parameters){
          if(data.options.model_parameters[modelName] !== null && "filter_efficiency" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].filter_efficiency /= 100
          }
          if(data.options.model_parameters[modelName] !== null && "ducts_removal" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].ducts_removal /= 100
          }
          if(data.options.model_parameters[modelName] !== null && "other_removal" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].other_removal /= 100
          }
          if(data.options.model_parameters[modelName] !== null && "fraction_immune" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].fraction_immune /= 100
          }
          if(data.options.model_parameters[modelName] !== null && "people_with_masks" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].people_with_masks /= 100
          }

        }
      }
    }
    return JSON.stringify(data, null, 2)
  }

  // from archABM to builder
  const configParser = (config) => {
    let data = JSON.parse(JSON.stringify(config))
    // return data
    // let data = config
    
    if ("events" in data){
      data.events.forEach(event => {
        if(event !== null && "schedule" in event && event.schedule !== null){
          event.schedule = event.schedule.map(interval => {
              if(interval !== null){
                return {"schedule": interval.map(mins2time)}
              }
              return interval
          })         
        }
        if(event !== null && "repeat_min" in event && "repeat_max" in event){
          event.repeat = [event.repeat_min, event.repeat_max]
          delete event.repeat_min
          delete event.repeat_max
        }
        if(event !== null && "duration_min" in event && "duration_max" in event){
          event.duration = [event.duration_min, event.duration_max]
          delete event.duration_min
          delete event.duration_max
        }
        if(event !== null && "mask_efficiency" in event){
          event.mask_efficiency *= 100
        }
      })
    }
    if("options" in data){
      if(data.options !== null && "ratio_infected" in data.options){
        data.options.ratio_infected *= 100
      }
      if(data.options !== null && "model_parameters" in data.options){
        if(data.options.model_parameters !== null  && modelName in data.options.model_parameters){
          if(data.options.model_parameters[modelName] !== null && "filter_efficiency" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].filter_efficiency *= 100
          }
          if(data.options.model_parameters[modelName] !== null && "ducts_removal" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].ducts_removal *= 100
          }
          if(data.options.model_parameters[modelName] !== null && "other_removal" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].other_removal *= 100
          }
          if(data.options.model_parameters[modelName] !== null && "fraction_immune" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].fraction_immune *= 100
          }
          if(data.options.model_parameters[modelName] !== null && "people_with_masks" in data.options.model_parameters[modelName]){
            data.options.model_parameters[modelName].people_with_masks *= 100
          }

        }
      }
    }
    return data
  }

  return (

    <div style={{ padding: '40px', maxWidth: '1200px' }}>
      <Title keyboard type="primary" level={3}>archABM configuration designer</Title>
      <Space>

      <Button 
        block 
        type="ghost" 
        shape="default" 
        onClick={onClear}
        icon={<ClearOutlined />}
        style={{width: '128px'}}
        >
        Clear all
      </Button>
      <Button 
        block 
        type="ghost" 
        shape="default" 
        onClick={() => onLoad(config_basic)}
        icon={<LayoutOutlined />}
        style={{width: '128px'}}
        >
        Load basic
      </Button>
      <Button 
        block 
        type="ghost" 
        shape="default" 
        onClick={() => onLoad(config_office)}
        icon={<GroupOutlined />}
        style={{width: '128px'}}
      >
        Load office
      </Button>
      </Space>
      <Divider />

      <Form
        form={form}
        name="dynamic_form_nest_item"
        onFinish={onFinish}
        onFinishFailed={onFinishFailed}
        autoComplete="off"
        layout="horizontal"
        // fields={state}
        onFieldsChange={onFieldsChange}
      >
        <Steps 
          direction="horizontal"
          current={current}
          onChange={onStepsChange}
          style={{}}
        >
          <Step title="People" />
          <Step title="Events" />
          <Step title="Places" />
          <Step title="Options" />
        </Steps>
        <div style={{ padding: '20px', minHeight: '400px' }}>
          {current === 0 && renderPeople()}
          {current === 1 && renderEvents()}
          {current === 2 && renderPlaces()}
          {current === 3 && renderOptions()}
        </div>
        {renderStepsButtons()}
      </Form>
      <Divider/>

      {/* <Button 
        block 
        type="ghost" 
        shape="default" 
        icon={<DownloadOutlined />} 
        onClick={onDownload}
        style={{width: '150px'}}
        >
        config.json
      </Button> */}


      
      {/* <pre className="language-bash">{JSON.stringify(state, null, 2)}</pre> */}
      {/* <pre className="language-bash">{configBuilder()}</pre> */}
    </div>
  )
};


export default App;